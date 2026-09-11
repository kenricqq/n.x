{
  host,
  lib,
  paths,
  pkgs,
  machine,
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

  inherit (host)
    isDarwin
    isLinux
    ;

in
{
  imports = [
    ./setup.nix

    ./helix.nix
    ./knowledge-tools.nix
    ./shell-commands.nix
    ./yazi.nix
    ./thunderbolt.nix

    ./sync.nix # restic/rsync/syncthing

    ./nushell.nix
    ./zsh.nix

    ./diagnostics.nix
    ./file-tools.nix
    ./nix-tools.nix

    ./display.nix
    ./navigation.nix
    ./media.nix
    ./security.nix # age/sops/gpg
    ./ssh.nix

    inputs.nixcord.homeModules.nixcord
  ]
  ++ lib.optionals isDarwin [
    ./macos/sketchybar.nix
    ./macos/aerospace.nix
  ];

  home = {
    shellAliases = aliases.common;

    packages =
      with pkgs;
      [
        curlie
        dnsutils # dig
        fastfetch

        #### TO SORT ###
        # # qui # qBittorrent
        # # signal-cli
        # # telegram-bot-api

        # ghostscript # pdf utility (ex. merge)
        # clipboard-jh

        # # esp
        # espflash

        # coreutils-full # gnu core utils

        # curlie # curl
        # procs # ps
        # sd # sed
        # mprocs # run multiple commands in parallel
        # toolong # log files
        # # ck
        # gum # shell script ui
        # entr # run command on file change
        # scooter # interactive search and replace
        # kondo # clean deps and build artifacts from proj

        # # tldr # community man
        # cht-sh # cli for cheat.sh (comprehensive cheatsheets)
        # # tlrc # tldr client in rs

        # # gping # ping with a graph
        # dnscrypt-proxy
        # # openapi-tui
        # # sshs

        # ## data manipulation
        # jnv # interactive JSON viewer + jq filter (rs)
        # fx # JSON viewer with vim bindings
        # jql # query json from cli
        # gojq
        # yq-go # YAML, TOML, JSON and XML processor
        # dasel # select/put/delete data from files
        # hexyl # hex viewer
        # sttr # text transformation

        # # Rust Dev
        # # cargo-watch
        # cargo-make
        # cargo-update
        # cargo-binstall
        # crates-tui # explore crates.io
        # # dioxus-cli

        # # other
        # mdbook # create book from md files
        # mdbook-linkcheck2 # check links
        # # ttyper # terminal typing test
        # # lychee # broken links checker
        # # puffin # personal finance dashboard
        # # bagels # tui expense tracker
        # # calcure # tui calendar + task manager
        # # ticker # cli stock ticker
        # # sc-im # spreadsheet calculator
        # # presenterm # md cli slideshow

        # wget
        # unzip
        # tree
        # jq

        # # Modern CLI tools
        # procs # Better ps

        # # to get greetd working
        # meson
        # gcc

        # greetd
        # dbus

        # wayland
        # wayland-protocols
        # wlroots_0_20

        # libglvnd
        # freetype
        # fontconfig

        # cairo
        # pango
        # harfbuzz

        # libxkbcommon
        # glib

        # tomlplusplus
        # nlohmann_json
        # stb

        # libwebp
        # librsvg

        # (pkgs.writeShellApplication {
        #   name = "vite-public-paths";
        #   text = ''
        #     exec ${pkgs.bun}/bin/bun ${./scripts/vite-public-paths/bin/vite-public-paths.js} "$@"
        #   '';
        # })
      ]
      ++ lib.optionals isLinux [
        handy
        wtype # needed for handy

        comfyui
      ]
      ++ lib.optionals isDarwin [
        m-cli # useful macOS CLI commands
      ];

    sessionPath =
      (map (f: "${paths.home}/${f}") [
        ".cargo/bin"
        ".local/bin"
        ".nix-profile/bin"
        "go/bin"
        ".bun/bin"
        ".cache/.bun/bin"
        # ".rustup/toolchains/esp/xtensa-esp-elf/esp-15.2.0_20250920/xtensa-esp-elf/bin"
      ])
      ++ lib.optionals isDarwin [
        "/opt/homebrew/bin"
        "/opt/homebrew/sbin"
        "/run/current-system/sw/bin"
        "/nix/var/nix/profiles/default/bin"
        "/etc/profiles/per-user/${machine.user}/bin"
      ]
      ++ lib.optionals isLinux [
        "${paths.home}/.nix-profile/opt/codex-desktop/resources/cua_node/bin"
      ];

    sessionVariables = {
      NX = paths.nixrt;
      HM = paths.hm;
      DW = paths.darwin;
      DOT = paths.dots;
      SCRIPTS = paths.scripts;
      SNIPPETS_PATH = paths.snippets; # for scls
      # SHARE = path.share;

      # NODE_PATH = "${home}/.cache/.bun/install/global/node_modules";

      EDITOR = "hx";
      VISUAL = "hx";
      PAGER = "less -R";
      LANG = "en_US.UTF-8";

      # }
      # // lib.optionalAttrs isDarwin {
      # DARWIN_HOST = hostName;
      # LIBCLANG_PATH = "${home}/.rustup/toolchains/esp/xtensa-esp32-elf-clang/esp-20.1.1_20250829/esp-clang/lib";
      # DYLD_FALLBACK_LIBRARY_PATH = "/opt/homebrew/lib";
    };

    file =
      let
        dotfiles = builtins.listToAttrs (
          (lib.mapAttrsToList (k: v: lib.nameValuePair ".config/${k}" v) (
            {
              "yazi/flavors" = "yazi/flavors";
              "hunk" = "hunk";
              "jj/config.toml" = "jj/config.toml";
              "niri" = "niri";
              "nushell/modules" = "nushell/modules";
              "ghostty" = "ghostty";
            }
            // lib.optionalAttrs isDarwin {
              "aerospace" = "aerospace";
              "sketchybar" = "sketchybar";
              # "rio/config.toml" = "rio/config.toml";
            }
            // lib.optionalAttrs isLinux {
              "ghostty" = "ghostty";
              "quickshell" = "quickshell";
            }
          ))
          ++ (lib.mapAttrsToList lib.nameValuePair {
            # agents
            ".codex/prompts" = "codex/prompts";
            ".codex/skills" = "codex/skills";
            ".codex/automations" = "codex/automations";
            ".codex/config.toml" = "codex/config.toml";
            ".codex/agent.config.toml" = "codex/agent.config.toml";
            ".codex/deep-review.config.toml" = "codex/deep-review.config.toml";
            ".codex/keybindings.json" = "codex/keybindings.json";
            ".codex/hooks.json" = "codex/hooks.json";

            ".pi/agent/settings.json" = "pi/agent/settings.json";

            # ".agent-of-empires/config.toml" = "agent-of-empires/config.toml";
          })
          ++ lib.optionals isDarwin (
            lib.mapAttrsToList (k: v: lib.nameValuePair "Library/Application Support/${k}" v) {
              "com.mitchellh.ghostty" = "ghostty";
              "dooit/config.py" = "dooit/config.py";
            }
          )
        );
      in
      (lib.mapAttrs (_: paths.mkDotFile) dotfiles)
      // lib.optionalAttrs isDarwin {
        # ensure launchd log directory exists so glance can start at login
        "Library/Logs/glance/.keep".text = "";
      };
  };
}
