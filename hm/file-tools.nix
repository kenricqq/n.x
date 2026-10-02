{ pkgs, ... }:

{
  programs = {
    numbat = {
      enable = true;
      settings = {
        exchange-rates = {
          fetching-policy = "on-first-use";
        };
        intro-banner = "short";
        prompt = "> ";
      };
    };

    # shell history
    atuin = {
      enable = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;
      # Nushell 0.115 warns because Atuin's generated Nu init gives both
      # Ctrl-R and Up bindings the same name. Keep Ctrl-R and let Nu's normal
      # history/hints handle Up.
      flags = [ "--disable-up-arrow" ];
      settings = {
        ctrl_n_shortcuts = true;
        enter_accept = true;
        filter_mode = "directory";
        inline_height = 20;
        invert = false;
        keymap_mode = "vim-insert"; # auto
        style = "auto";
      };
    };

    bat = {
      enable = true;
      config = {
        map-syntax = [
          "*.jenkinsfile:Groovy"
          "*.props:Java Properties"
        ];
        pager = "less -FR";
        theme = "TwoDark";
      };
      syntaxes = {
        gleam = {
          src = pkgs.fetchFromGitHub {
            owner = "molnarmark";
            repo = "sublime-gleam";
            rev = "2e761cdb1a87539d827987f997a20a35efd68aa9";
            hash = "sha256-Zj2DKTcO1t9g18qsNKtpHKElbRSc9nBRE2QBzRn9+qs=";
          };
          file = "syntax/gleam.sublime-syntax";
        };
      };
      themes = {
        dracula = {
          src = pkgs.fetchFromGitHub {
            owner = "dracula";
            repo = "sublime"; # Bat uses sublime syntax for its themes
            rev = "26c57ec282abcaa76e57e055f38432bd827ac34e";
            sha256 = "019hfl4zbn4vm4154hh3bwk6hm7bdxbr1hdww83nabxwjn99ndhv";
          };
          file = "Dracula.tmTheme";
        };
      };
    };

    # find files by fuzzy filename
    # json processor
    jq = {
      enable = true;
    };
    # # jq playground
    # jqp = {
    #   enable = true;
    #   settings = {
    #     theme = {
    #       chromaStyleOverrides = {
    #         kc = "#009900 underline";
    #       };
    #       name = "monokai";
    #     };
    #   };
    # };
    # fzf cheatsheet for cli, can wrap tldr
    # navi = {
    #   enable = true;
    # };
    # pandoc = {
    #   enable = true;
    # };
    # command suggestion/autofix
    # pay-respects = {
    #   enable = true;
    #   enableZshIntegration = true;
    #   options = [
    #     "--alias"
    #     "f"
    #   ];
    # };
    # rTorrent BitTorrent client
    # rtorrent = {
    #   enable = true;
    # };
    # text search through files
    # ripgrep = {
    #   enable = true;
    #   arguments = [
    #     "--max-columns-preview"
    #     "--colors=line:style:bold"
    #   ];
    # };
    # extend rg to PDFs, EBooks, zip, tar, etc
    # terminal music player
    # cli todo manager
    # taskwarrior = {
    #   enable = true;
    #   package = pkgs.taskwarrior3;
    #   colorTheme = "dark-blue-256";
    #   config = {
    #     confirmation = false;
    #     report.minimal.filter = "status:pending";
    #     report.active.columns = [
    #       "id"
    #       "start"
    #       "entry.age"
    #       "priority"
    #       "project"
    #       "due"
    #       "description"
    #     ];
    #     report.active.labels = [
    #       "ID"
    #       "Started"
    #       "Age"
    #       "Priority"
    #       "Project"
    #       "Due"
    #       "Description"
    #     ];
    #     # taskd = {
    #     #   certificate = "/path/to/cert";
    #     #   key = "/path/to/key";
    #     #   ca = "/path/to/ca";
    #     #   server = "host.domain:53589";
    #     #   credentials = "Org/First Last/cf31f287-ee9e-43a8-843e-e8bbd5de4294";
    #     # };
    #   };
    # };
    # faster tldr, man pages
    tealdeer = {
      enable = true;
      # manual: tldr --update
      enableAutoUpdates = false;
      settings = {
        # display = {
        #   compact = true;
        #   use_pager = true;
        # };
      };
    };
  };
  home.packages = with pkgs; [
    _7zz # 7-zip

    ouch # (de)compression
    glow

    sd # scripted find and replace
    scooter # interactive project-wide find and replace
    jnv # interactive jq filtering
    yq-go # query and edit YAML and other structured formats

    ghostscript # image/pdf manipulation

    python314Packages.curl-cffi
  ];
}
