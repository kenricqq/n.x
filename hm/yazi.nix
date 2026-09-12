{ pkgs, paths, ... }:

let
  yaziRsPlugin =
    name: rev: hash:
    pkgs.runCommand "${name}.yazi-${rev}" { } ''
      mkdir -p "$out"
      cp -R ${
        pkgs.fetchFromGitHub {
          owner = "yazi-rs";
          repo = "plugins";
          inherit rev hash;
        }
      }/${name}.yazi/. "$out/"

      if [ -f "$out/init.lua" ] && [ ! -f "$out/main.lua" ]; then
        cp "$out/init.lua" "$out/main.lua"
      fi
    '';
in
{
  programs.yazi = {
    enable = true;
    enableNushellIntegration = true;
    enableZshIntegration = true;
    shellWrapperName = "y";
    extraPackages = [ pkgs.hexyl ];
    plugins = with pkgs.yaziPlugins; {
      piper = piper;
      faster-piper = pkgs.fetchFromGitHub {
        owner = "alberti42";
        repo = "faster-piper.yazi";
        rev = "bb90261";
        hash = "sha256-a7/KTIoIU9idxhYmYFsp6/ezmiBK/mEYfEz9zqZZiEU=";
      };
      fr = pkgs.fetchFromGitHub {
        owner = "lpnh";
        repo = "fr.yazi";
        rev = "aa88cd4";
        hash = "sha256-3D1mIQpEDik0ppPQo+/NIhCxEu/XEnJMJ0HiAFxlOE4=";
      };
      diff = diff;
      smart-filter =
        yaziRsPlugin "smart-filter" "ec97f88"
          "sha256-By8XuqVJvS841u+8Dfm6R8GqRAs0mO2WapK6r2g7WI8=";
      smart-enter = smart-enter;
      lazygit = lazygit;
      chmod = chmod;
      full-border =
        yaziRsPlugin "full-border" "62f0789"
          "sha256-PSVzjC1sdaIOtK5ave4kn3Ck8YwpjO3N9uV/WE6Skdo=";
      no-status = no-status;
      toggle-pane = toggle-pane;
      mediainfo = mediainfo;
      jjui = jjui;
      vcs-files = vcs-files;
      # utils = ./yazi_plugins/utils.yazi;
    };
    # initLua = "./dotfiles/yazi_init.lua";
    initLua = ''
      require("no-status"):setup()
    '';
    keymap = {
      input.prepend_keymap = [
        {
          run = "close";
          on = [ "<C-q>" ];
        }
        {
          run = "close --submit";
          on = [ "<Enter>" ];
        }
        {
          run = "escape";
          on = [ "<Esc>" ];
        }
        {
          run = "backspace";
          on = [ "<Backspace>" ];
        }
      ];
      mgr = {
        prepend_keymap = [
          {
            on = "T";
            run = "plugin toggle-pane min-preview";
            desc = "Show or hide the preview pane";
          }
          {
            "on" = [
              "F"
              "A"
            ];
            "run" = "plugin fr rga";
            "desc" = "Search file by content (rga)";
          }
          {
            on = "T";
            run = "plugin toggle-pane max-preview";
            desc = "Maximize or restore the preview pane";
          }
          {
            on = "<C-p>";
            run = "shell -- qlmanage -p \"$@\"";
            desc = "macOS preview files with system quick look";
          }
          {
            on = "<C-d>";
            run = "plugin diff";
            desc = "Diff the selected with the hovered file";
          }
          {
            on = [
              "F"
              "F"
            ];
            run = "plugin smart-filter";
            desc = "Smart filter";
          }
          {
            on = "l";
            run = "plugin smart-enter";
            desc = "Enter the child directory, or open the file";
          }
          {
            on = [
              "g"
              "r"
            ];
            run = "shell -- ya emit cd \"$(git rev-parse --show-toplevel)\"";
            desc = "Go to git root";
          }
          {
            on = [
              "g"
              "m"
            ];
            run = "cd \"${paths.nixrt}\"";
            desc = "Go to Nix config";
          }
          {
            on = "<C-g>";
            run = "plugin lazygit";
            desc = "run lazygit";
          }
          {
            on = [
              "c"
              "m"
            ];
            run = "plugin chmod";
            desc = "Chmod on selected files";
          }

          # custom
          {
            on = "E";
            run = "shell --block -- eza -TL=3 --color=always --icons=always --group-directories-first --no-quotes \"$@\" | LESSUTFCHARDEF=E000-F8FF:p,F0000-FFFFD:p,100000-10FFFD:p less -R";
            desc = "Full eza tree for hovered/selected paths";
          }
          {
            run = "escape";
            on = [ "<Esc>" ];
          }
          {
            run = "quit";
            on = [ "q" ];
          }
          {
            run = "close";
            on = [ "<C-q>" ];
          }
          # { run = "plugin utils"; on = [ "u" ]; desc = "ls folder"; }
          # { run  = "shell '$SHELL' --block"; on = "!"; desc = "Open shell here"; }
        ];
      };
    };
    settings = {
      log = {
        enabled = false;
      };
      mgr = {
        show_hidden = false;
        sort_by = "mtime";
        # sort_by = "alphabetical";
        sort_dir_first = true;
        sort_reverse = true;
        ratio = [
          2
          3
          4
        ];
      };
      opener = {
        bulk-rename = [
          {
            run = "hx \"$@\"";
            block = true;
          }
        ];
        # edit = [
        #   {
        #     run = "hx \"$@\"";
        #     block = true;
        #   }
        # ];
        set-wallpaper = [
          {
            run = ''
              	osascript -e 'on run {img}' -e 'tell application "System Events" to set picture of every desktop to img' -e 'end run' "$0"
            '';
            for = "macos";
            desc = "Set as wallpaper";
          }
        ];
      };
      open = {
        prepend_rules = [
          {
            mime = "image/*";
            use = [
              "open"
              "set-wallpaper"
            ];
          }
        ];
      };
      preview = {
        image_delay = 0;
        # max_width = 1000;
        # max_height = 1000;
      };
      tasks = {
        # Don't ask on quit for speculative preview warmers.
        suppress_preload = true;
        # image_bound = [
        #   6000
        #   6000
        # ];
      };
      plugin = {
        prepend_previewers = [
          {
            url = "*.tar*";
            # run = "piper --format=url -- tar tf \"$1\"";
            # run = "faster-piper --rely-on-preloader --format=url";
            run = "faster-piper --format=url -- tar tf \"$1\"";
          }
          {
            url = "*.txt.gz";
            run = "faster-piper -- gzip -dc \"$1\"";
          }
          {
            url = "*.csv";
            run = "faster-piper -- bat -p --color=always \"$1\"";
          }
          {
            url = "*.md";
            run = "faster-piper -- CLICOLOR_FORCE=1 glow -w=$w -s=dracula -- \"$1\"";
          }
          {
            url = "*/";
            run = "faster-piper -- eza -TL=3 --git-ignore -I 'node_modules|.git|target|dist|build|.next|.svelte-kit' --color=always --icons=always --group-directories-first --no-quotes \"$1\"";
          }
          {
            mime = "application/sqlite3";
            run = "faster-piper -- sqlite3 \"$1\" \".schema --indent\"";
          }
          # hexyl as fallback previewer instead of file
          {
            url = "*/.hex";
            run = "faster-piper -- hexyl --border=none --terminal-width=$w \"$1\"";
          }
          {
            mime = "{audio,video,image}/*";
            run = "mediainfo";
          }
        ];
        prepend_preloaders = [
          {
            url = "*.tar*";
            # run = "piper --format=url -- tar tf \"$1\"";
            run = "faster-piper --format=url -- tar tf \"$1\"";
          }
          {
            url = "*.txt.gz";
            run = "faster-piper -- gzip -dc \"$1\"";
          }
          {
            url = "*.csv";
            run = "faster-piper -- bat -p --color=always \"$1\"";
          }
          {
            url = "*.md";
            run = "faster-piper -- CLICOLOR_FORCE=1 glow -w=$w -s=dracula -- \"$1\"";
          }
          {
            url = "*/";
            run = "faster-piper -- eza -TL=3 --git-ignore -I 'node_modules|.git|target|dist|build|.next|.svelte-kit' --color=always --icons=always --group-directories-first --no-quotes \"$1\"";
          }
          {
            mime = "application/sqlite3";
            run = "faster-piper -- sqlite3 \"$1\" \".schema --indent\"";
          }
          # hexyl as fallback previewer instead of file
          {
            url = "*/.hex";
            run = "faster-piper -- hexyl --border=none --terminal-width=$w \"$1\"";
          }
          {
            mime = "{audio,video,image}/*";
            run = "mediainfo";
          }
        ];
      };
    };
    theme = {
      flavor = {
        # kanagawa, rose-pine-moon
        # use = "dracula";
        # use = "kanagawa-dragon";
      };
    };
  };
}
