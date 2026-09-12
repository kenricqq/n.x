{
  config,
  lib,
  machine,
  paths,
  pkgs,
  ...
}:

let
  aliases = import ./alias.nix {
    inherit
      lib
      machine
      paths
      pkgs
      ;
  };

  p10kConfig = "${config.xdg.configHome}/zsh/.p10k.zsh";

  # Required by the asynchronous Jujutsu segment in the P10k config.
  zshAsync = pkgs.fetchFromGitHub {
    owner = "mafredri";
    repo = "zsh-async";
    rev = "ee1d11b68c38dec24c22b1c51a45e8a815a79756";
    hash = "sha256-mkTmgSnfoZlTaOPhw0Y0yG1BkZv+oTo/eEisZZTN5nM=";
  };
in
{
  xdg.configFile = {
    "zsh/async.zsh".source = "${zshAsync}/async.zsh";
    "zsh/.p10k.zsh" = paths.mkDotFile "p10k/.p10k.zsh";
  };

  programs.zsh = {
    enable = true;
    autocd = true;
    defaultKeymap = "viins";
    enableCompletion = true;

    # Common aliases come from home.shellAliases in _base.nix.
    shellAliases = aliases.zsh;

    siteFunctions = {
      root = ''
        local repo_root

        if ! repo_root="$(command git rev-parse --show-toplevel 2>/dev/null)"; then
          print -u2 -- "root: not inside a Git repository"
          return 1
        fi

        builtin cd -- "$repo_root"
      '';

      avenv = ''
        local repo_root venv_dir activate_file

        if ! repo_root="$(command git rev-parse --show-toplevel 2>/dev/null)"; then
          print -u2 -- "avenv: not inside a Git repository"
          return 1
        fi

        if [[ -r "$repo_root/.venv/bin/activate" ]]; then
          venv_dir="$repo_root/.venv"
        elif (( ''${+commands[fd]} )); then
          venv_dir="$(command fd --hidden --no-ignore --type directory '^\.venv$' "$repo_root" 2>/dev/null | command head -n 1)"
          venv_dir="''${venv_dir%/}"
        else
          venv_dir="$(command find "$repo_root" -type d -name .venv -print -quit 2>/dev/null)"
        fi

        activate_file="''${venv_dir:+$venv_dir/bin/activate}"
        if [[ -z "$activate_file" || ! -r "$activate_file" ]]; then
          print -u2 -- "avenv: no readable .venv/bin/activate found under $repo_root"
          return 1
        fi

        source "$activate_file"
      '';

      mkcd = ''
        if (( $# != 1 )); then
          print -u2 -- "usage: mkcd DIRECTORY"
          return 2
        fi

        command mkdir -p -- "$1" && builtin cd -- "$1"
      '';

      jjw = ''
        local subcommand="''${1:-cd}" target argument

        if [[ "$subcommand" == cd || "$subcommand" == new ]]; then
          if [[ "$subcommand" == new ]]; then
            for argument in "''${@:2}"; do
              if [[ "$argument" == -h || "$argument" == --help ]]; then
                command jjw "$@"
                return
              fi
            done
          fi

          if (( $# == 0 )); then
            target="$(command jjw cd)" || return
          else
            target="$(command jjw "$@")" || return
          fi
          [[ -n "$target" ]] || return 1
          builtin cd -- "$target"
        else
          command jjw "$@"
        fi
      '';
    };

    autosuggestion = {
      enable = true;
      strategy = [
        "completion"
        "history"
        "match_prev_cmd"
      ];
    };

    fastSyntaxHighlighting.enable = true;

    plugins = [
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];

    initContent = lib.mkMerge [
      (lib.mkOrder 50 ''
        typeset -g POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
        typeset -g POWERLEVEL9K_INSTANT_PROMPT_COMMAND_LINES=0
        typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
      '')

      # Home Manager sources programs.zsh.plugins at order 900.
      (lib.mkOrder 910 ''
        if [[ -r ${lib.escapeShellArg p10kConfig} ]]; then
          source ${lib.escapeShellArg p10kConfig}
        fi
      '')

      (lib.mkOrder 1000 ''
        unsetopt BEEP

        # Vi mode cursor shapes: insert = bar, normal = block.
        function zle-keymap-select() {
          case $KEYMAP in
            vicmd) printf '\e[2 q' ;;
            viins|main) printf '\e[6 q' ;;
          esac
        }
        function zle-line-init() { printf '\e[6 q' }
        function zle-line-finish() { printf '\e[0 q' }
        zle -N zle-keymap-select
        zle -N zle-line-init
        zle -N zle-line-finish

        # Helix-like prompt editing on top of Zsh vi mode.
        typeset -g HX_ZLE_SELECTION=""
        typeset -g HX_ZLE_HEAD_STYLE='fg=#1f1f1f,bg=#ffd75f,bold'

        function hx-zle-highlight-head() {
          region_highlight=("''${(@)region_highlight:#*memo=hx-zle-head}")
          (( REGION_ACTIVE )) || return

          local len=$#BUFFER head=$CURSOR
          (( len > 0 )) || return
          (( head >= len )) && head=$(( len - 1 ))
          (( head < 0 )) && head=0
          region_highlight+=("$head $(( head + 1 )) $HX_ZLE_HEAD_STYLE memo=hx-zle-head")
        }

        if (( ''${+widgets[zle-line-pre-redraw]} )) && [[ ''${widgets[zle-line-pre-redraw]} != user:hx-zle-line-pre-redraw ]]; then
          zle -A zle-line-pre-redraw hx-zle-prev-line-pre-redraw
        fi

        function hx-zle-line-pre-redraw() {
          if (( ''${+widgets[hx-zle-prev-line-pre-redraw]} )); then
            zle hx-zle-prev-line-pre-redraw "$@"
          fi
          hx-zle-highlight-head
        }

        function hx-zle-select-line() {
          HX_ZLE_SELECTION=line
          MARK=0
          CURSOR=$#BUFFER
          REGION_ACTIVE=1
          region_highlight=("0 $#BUFFER standout")
          zle -R
        }

        function hx-zle-clear-selection() {
          HX_ZLE_SELECTION=""
          REGION_ACTIVE=0
          region_highlight=()
          zle -R
        }

        function hx-zle-delete() {
          if [[ $HX_ZLE_SELECTION == line ]]; then
            CUTBUFFER=$BUFFER
            BUFFER=""
            CURSOR=0
            zle hx-zle-clear-selection
          elif (( REGION_ACTIVE )); then
            zle kill-region
            zle hx-zle-clear-selection
          else
            zle delete-char
          fi
        }

        function hx-zle-change() {
          zle hx-zle-delete
          zle -K viins
        }

        function hx-zle-yank() {
          if [[ $HX_ZLE_SELECTION == line ]]; then
            CUTBUFFER=$BUFFER
            zle hx-zle-clear-selection
          elif (( REGION_ACTIVE )); then
            zle copy-region-as-kill
            zle hx-zle-clear-selection
          else
            CUTBUFFER=$BUFFER
          fi
        }

        zle -N zle-line-pre-redraw hx-zle-line-pre-redraw
        zle -N hx-zle-select-line
        zle -N hx-zle-clear-selection
        zle -N hx-zle-delete
        zle -N hx-zle-change
        zle -N hx-zle-yank

        for hx_keymap in vicmd visual; do
          bindkey -M $hx_keymap 'gh' beginning-of-line
          bindkey -M $hx_keymap 'gl' end-of-line
          bindkey -M $hx_keymap 'x' hx-zle-select-line
          bindkey -M $hx_keymap ';' hx-zle-clear-selection
          bindkey -M $hx_keymap 'd' hx-zle-delete
          bindkey -M $hx_keymap 'c' hx-zle-change
          bindkey -M $hx_keymap 'y' hx-zle-yank
          bindkey -M $hx_keymap 'p' yank
          bindkey -M $hx_keymap 'u' undo
          bindkey -M $hx_keymap 'U' redo
        done
        unset hx_keymap

        bindkey '^F' autosuggest-accept

        # Edit the whole prompt in Helix at the current cursor position.
        function hx-zle-edit-command-line() {
          emulate -L zsh

          local cursor=$CURSOR tmpfile row col
          local -a left_lines

          tmpfile="$(mktemp "''${TMPDIR:-/tmp}/zsh-edit-command-line.XXXXXX")" || return
          print -r -n -- "$BUFFER" >| "$tmpfile"

          left_lines=("''${(@f)LBUFFER}")
          row=$#left_lines
          col=$(( $#left_lines[-1] + 1 ))
          (( row )) || row=1

          (( $+zle_bracketed_paste )) && print -r -n - $zle_bracketed_paste[2]
          printf '\e[0 q'
          zle -I
          command hx "$tmpfile:$row:$col"
          (( $+zle_bracketed_paste )) && print -r -n - $zle_bracketed_paste[1]

          if [[ -r "$tmpfile" ]]; then
            BUFFER="$(<"$tmpfile")"
            CURSOR=$(( cursor > $#BUFFER ? $#BUFFER : cursor ))
          fi

          rm -f -- "$tmpfile"
          HX_ZLE_SELECTION=""
          REGION_ACTIVE=0
          region_highlight=()
          zle-keymap-select
          zle reset-prompt
        }

        zle -N hx-zle-edit-command-line
        bindkey '^O' hx-zle-edit-command-line
        bindkey -M viins '^O' hx-zle-edit-command-line
        bindkey -M vicmd '^O' hx-zle-edit-command-line
      '')
    ];
  };
}
