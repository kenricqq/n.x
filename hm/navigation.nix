{ pkgs, ... }:

{
  programs = {
    fd = {
      enable = true;
      extraOptions = [
        "--no-ignore"
        "--absolute-path"
      ];
      hidden = true;
      ignores = [
        ".git/"
        "*.bak"
      ];
    };

    # fuzzy finder
    fzf = {
      enable = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;
      # tmux = {
      #   enableShellIntegration = true;
      # };
      changeDirWidget = {
        command = "fd --type d";
        options = [
          "--preview 'tree -C {} | head -200'"
        ];
      };
      colors = {
        bg = "#1e1e1e";
        "bg+" = "#1e1e1e";
        fg = "#d4d4d4";
        "fg+" = "#d4d4d4";
      };
      defaultCommand = "fd --hidden --follow --exclude .git";
      defaultOptions = [
        "--height 50%"
        "--layout=reverse"
        "--border"
        "--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
      ];
      fileWidget = {
        command = "fd --type f";
        options = [
          "--preview 'head {}'"
        ];
      };
      historyWidget = {
        command = "";
        options = [
          "--sort"
          "--exact"
        ];
      };
    };

    eza = {
      enable = true;
      colors = "auto";
      extraOptions = [
        "--group-directories-first"
        "--header"
      ];
      git = true;
      icons = "auto";
    };

    ripgrep = {
      enable = true;
      arguments = [
        "--max-columns-preview"
        "--colors=line:style:bold"
      ];
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;
    };

    # general purpose fuzzy finder
    television = {
      enable = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;
      channels = {
        git-diff = {
          metadata = {
            description = "A channel to select files from git diff commands";
            name = "git-diff";
            requirements = [
              "git"
            ];
          };
          preview = {
            command = "git diff HEAD --color=always -- '{}'";
          };
          source = {
            command = "git diff --name-only HEAD";
          };
        };
        git-log = {
          metadata = {
            description = "A channel to select from git log entries";
            name = "git-log";
            requirements = [
              "git"
            ];
          };
          preview = {
            command = "git show -p --stat --pretty=fuller --color=always '{0}'";
          };
          source = {
            command = "git log --oneline --date=short --pretty=\"format:%h %s %an %cd\" \"$@\"";
            output = "{split: :0}";
          };
        };
        tldr = {
          metadata = {
            description = "Browse TLDR pages";
            name = "tldr";
          };
          preview = {
            command = "tldr '{}'";
          };
          source = {
            command = "tldr --list";
          };
          keybindings = {
            ctrl-e = "actions:open";
          };
          actions.open = {
            command = "tldr '{}'";
            mode = "execute";
          };
        };
      };
      settings = {
        tick_rate = 50;
        ui = {
          use_nerd_font_icons = true;
          ui_scale = 120;
          show_preview_panel = false;
        };
      };
    };
  };

  home.packages = with pkgs; [
    ripgrep-all

    tree # tree view for git-aware file lists
  ];
}
