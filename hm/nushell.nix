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
in
{
  programs.starship = {
    enable = true;
    enableNushellIntegration = true;
    enableZshIntegration = false;
    configPath = "${paths.dots}/starship/starship.toml";

    # settings = {
    #   format = "$directory$git_branch$git_status$line_break$character";

    #   character = {
    #     success_symbol = "[❯](bold mauve)";
    #     error_symbol = "[❯](bold red)";
    #   };

    #   directory = {
    #     style = "bold blue";
    #     truncate_to_repo = false;
    #   };

    #   git_branch = {
    #     style = "bold purple";
    #   };
    # };
  };

  # Keep the live Ghostty directory symlink; generate only its startup include.
  xdg.configFile."ghostty-nix.conf".text = ''
    command = ${lib.getExe config.programs.nushell.package} --login --config-home "${config.xdg.configHome}/nushell"
  '';

  programs.nushell = {
    enable = true;
    shellAliases = aliases.nushell;
    environmentVariables = builtins.removeAttrs config.home.sessionVariables [ "TERMINFO_DIRS" ];
    settings = {
      edit_mode = "vi";
      keybindings = [
        {
          name = "history_hint_complete";
          modifier = "control";
          keycode = "char_f";
          mode = [
            "emacs"
            "vi_insert"
          ];
          event.send = "HistoryHintComplete";
        }
      ];
      show_banner = false;
    };
    plugins = with pkgs.nushellPlugins; [
      formats
      gstat
      polars
      query
    ];
    # Consume the shared PATH even when Nushell starts outside a login shell.
    extraEnv = ''
      $env.PATH = (
        $env.PATH
        | prepend ${builtins.toJSON config.home.sessionPath}
        | uniq
      )
    '';
    extraConfig = ''
      use ~/.config/nushell/modules/completions-jj.nu *

      def _git-root [] {
        let result = (do { ^git rev-parse --show-toplevel } | complete)
        if $result.exit_code != 0 {
          let message = ($result.stderr | str trim)
          error make {
            msg: (if ($message | is-empty) { "Not inside a Git repository" } else { $message })
          }
        }

        $result.stdout | str trim | path expand
      }

      def --env root [] {
        cd (_git-root)
      }

      def --env avenv [venv?: path] {
        let selected = if $venv != null {
          $venv | path expand
        } else {
          let repo = (_git-root)
          let conventional = ($repo | path join ".venv")

          if ($conventional | path type) == "dir" {
            $conventional
          } else {
            let search = (
              do { ^fd --hidden --no-ignore --type directory --glob ".venv" $repo }
              | complete
            )
            if $search.exit_code != 0 {
              error make { msg: ($search.stderr | str trim) }
            }

            let candidates = (
              $search.stdout
              | lines
              | each {|candidate| $candidate | path expand }
            )
            match ($candidates | length) {
              0 => { error make { msg: $"No .venv directory found under ($repo)" } }
              1 => { $candidates | first }
              _ => {
                error make {
                  msg: $"Multiple .venv directories found under ($repo); pass one to `avenv`"
                }
              }
            }
          }
        }

        let bin = ($selected | path join "bin")
        if not (($bin | path join "python") | path exists) {
          error make { msg: $"Not a Python virtual environment: ($selected)" }
        }

        if "NU_VENV_ORIGINAL_PATH" not-in $env {
          $env.NU_VENV_ORIGINAL_PATH = $env.PATH
        }
        $env.PATH = ($env.NU_VENV_ORIGINAL_PATH | prepend $bin | uniq)
        $env.VIRTUAL_ENV = $selected
        $env.VIRTUAL_ENV_PROMPT = ($selected | path basename)
        hide-env --ignore-errors PYTHONHOME
      }

      def --env deactivate [] {
        if "NU_VENV_ORIGINAL_PATH" in $env {
          $env.PATH = $env.NU_VENV_ORIGINAL_PATH
          hide-env NU_VENV_ORIGINAL_PATH
        }
        hide-env --ignore-errors VIRTUAL_ENV VIRTUAL_ENV_PROMPT
      }

      def --env jjw [...args: string] {
        let subcommand = if ($args | is-empty) { "cd" } else { $args | first }
        let new_help = if $subcommand == "new" {
          $args | skip 1 | any {|argument| $argument in ["-h" "--help"] }
        } else {
          false
        }

        if (($subcommand in ["cd" "new"]) and not $new_help) {
          let command_args = if ($args | is-empty) { ["cd"] } else { $args }
          let result = (do { ^jjw ...$command_args } | complete)
          if $result.exit_code != 0 {
            let message = ($result.stderr | str trim)
            error make {
              msg: (if ($message | is-empty) { "jjw failed" } else { $message })
            }
          }

          let feedback = ($result.stderr | str trim)
          if not ($feedback | is-empty) {
            print --stderr $feedback
          }

          let target = ($result.stdout | str trim)
          if ($target | is-empty) {
            error make { msg: "jjw returned no workspace path" }
          }
          cd $target
        } else {
          ^jjw ...$args
        }
      }
    '';
  };
}
