{
  config,
  paths,
  pkgs,
  ...
}:

{
  programs = {
    delta = {
      enable = true;
      enableGitIntegration = true;
      # enableJujutsuIntegration = true;
      options = {
        side-by-side = true;
        decorations = {
          commit-decoration-style = "bold yellow box ul";
          file-style = "bold yellow ul";
          file-decoration-style = "none";
          hunk-header-decoration-style = "yellow box";
        };
        features = "decorations";
        whitespace-error-style = "22 reverse";
      };
    };
    git = {
      enable = true;
      attributes = [
        "*.pdf diff=pdf"
      ];
      settings = {
        aliases = {
          co = "checkout";
          rao = "remote add origin";
        };
        core = {
          pager = "hunk pager";
          whitespace = "trailing-space,space-before-tab";
        };
        delta = {
          navigate = "true";
        };
        # diff.tool = "delta";
        diff.tool = "difftastic";
        difftool = {
          prompt = false;
          difftastic.cmd = "${config.programs.difftastic.package}/bin/difft \"$LOCAL\" \"$REMOTE\"";
        };
        pager.difftool = true;
        merge = {
          conflictStyle = "zdiff3";
        };
      };
    };
    difftastic = {
      enable = true;
      git = {
        enable = false;
        mode = "difftool";
      };
      # jujutsu.enable = true;
      options = {
        # sort-paths = true;
        # tab-width = 8;
      };
    };
    jjui = {
      enable = true;
      configDir = "${paths.configHome}/.jjui";
      settings = {
        revisions = {
          revset = "";
          template = "builtin_log_compact";
        };
      };
    };
    jujutsu = {
      enable = true;
    };
    lazygit = {
      enable = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
      settings = {
        gui.theme = {
          activeBorderColor = [
            "blue"
            "bold"
          ];
          inactiveBorderColor = [ "cyan" ];
          selectedLineBgColor = [ "default" ];
        };
        git = {
          pagers = [
            {
              externalDiffCommand = "difft --color=always";
            }
          ];
        };
      };
    };
    # github cli
    gh = {
      enable = true;
      extensions = [
        pkgs.gh-eco
        pkgs.gh-f
      ];
      hosts = {
        "github.com" = {
          user = "kenricqq";
        };
      };
      settings = {
        aliases = {
          co = "pr checkout";
          pv = "pr view";
        };

        git_protocol = "ssh";

        prompt = "enabled";
      };
    };
    # cli dashboard for github
    gh-dash = {
      enable = true;
      # settings = {
      #   prSections = [
      #     {
      #       title = "My Pull Requests";
      #       filters = "is:open author:@me";
      #     }
      #   ];
      # };
    };
  };

  home.packages = with pkgs; [
    lazyjj
    glab # gitlab cli

    lefthook # git hooks manager (like husky)
    gitleaks # check for secrets
    act # run github actions locally
  ];
}
