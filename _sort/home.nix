{
  hostName ? "Kenrics-MacBook-Air",
  homeProfile ? "desktop",
  lib,
  pkgs,
  path,
  username ? "kenrictee",
  zls,
  zig,
  # ck-src,
  ...
}:

let
  inherit (path)
    dot
    home
    hm
    nixrt
    ;

  system = pkgs.stdenv.hostPlatform.system;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isDesktop = homeProfile == "desktop";

  bunxLatest =
    {
      bin,
      package ? bin,
    }:
    pkgs.writeShellApplication {
      name = bin;
      runtimeInputs = [ pkgs.bun ];
      text = ''
        exec bunx --bun \
          -p ${lib.escapeShellArg "${package}@latest"} \
          ${lib.escapeShellArg bin} "$@"
      '';
    };

  # ck = pkgs.rustPlatform.buildRustPackage {
  #   pname = "ck";

  #   # Version is up to you; you can derive from the git rev if you want
  #   version = "git-${ck-src.rev or "dev"}";

  #   # Use the source from the flake input
  #   src = ck-src;

  #   # Re-use the lockfile from the repo
  #   cargoLock.lockFile = "${ck-src}/Cargo.lock";

  #   nativeBuildInputs = with pkgs; [
  #     pkg-config
  #   ];

  #   buildInputs = with pkgs; [
  #     onnxruntime
  #   ];

  #   ORT_LIB_LOCATION = "${pkgs.onnxruntime}/lib";
  #   ORT_INCLUDE_LOCATION = "${pkgs.onnxruntime}/include";
  # };

  # shellAliases = import ./alias.nix;
  python-packages = import ./python.nix;

in
# user packages, not available in sudo mode
{
  xdg.enable = true;
  manual.manpages.enable = false;
  home = {
    username = lib.mkDefault username;
    homeDirectory = lib.mkDefault home;
    stateVersion = "26.05";
    enableNixpkgsReleaseCheck = false;

    sessionPath =
      (map (f: "$HOME/${f}") [
        ".cargo/bin"
        ".local/bin"
        ".nix-profile/bin"
        "go/bin"
        # ".pnpm"
        # ".rustup/toolchains/esp/xtensa-esp-elf/esp-15.2.0_20250920/xtensa-esp-elf/bin"
      ])
      ++ [
        "/run/current-system/sw/bin"
        "/nix/var/nix/profiles/default/bin"
        "/etc/profiles/per-user/$USER/bin"
      ]
      ++ (map (f: "$HOME/${f}") [
        ".bun/bin"
        ".cache/.bun/bin"
      ])
      ++ lib.optionals isDarwin [
        "/opt/homebrew/bin"
        "/opt/homebrew/opt"
      ];

    sessionVariables = {
      PROFILE_HOST = hostName;
      NX = nixrt;
      HM = hm;
      DW = path.darwin;
      DOT = dot;
      SCRIPTS = path.scripts;
      SNIPPETS_PATH = path.snippets; # for scls
      SHARE = path.share;

      PNPM_HOME = "${home}/.pnpm";
      NODE_PATH = "${home}/.cache/.bun/install/global/node_modules";

      EDITOR = "hx";
      # CODEX_HOME = "${dot}/codex";
      SOPS_AGE_KEY_FILE = "${nixrt}/secrets/keys.txt"; # sops key location
    }
    // lib.optionalAttrs isDarwin {
      DARWIN_HOST = hostName;
      SSH_AUTH_SOCK = "${home}/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
      LIBCLANG_PATH = "${home}/.rustup/toolchains/esp/xtensa-esp32-elf-clang/esp-20.1.1_20250829/esp-clang/lib";
      DYLD_FALLBACK_LIBRARY_PATH = "/opt/homebrew/lib";
    };

    # shellAliases = shellAliases;

    file =
      let
        dotfiles = builtins.listToAttrs (
          (lib.mapAttrsToList (k: v: lib.nameValuePair ".config/${k}" v) (
            {
              "zellij" = "zellij";
              "yazi/flavors" = "yazi/flavors";
              "hunk" = "hunk";
              "jj/config.toml" = "jj/config.toml";
              # "mpd/mpd.conf" = "mpd/mpd.conf";
            }
            // lib.optionalAttrs isDesktop {
              "aerospace" = "aerospace";
              "sketchybar" = "sketchybar";
              "rio/config.toml" = "rio/config.toml";
              # "homebrew/trust.json" = "homebrew/trust.json";
            }
          ))
          ++ lib.optionals isDesktop (
            lib.mapAttrsToList (k: v: lib.nameValuePair "Library/Application Support/${k}" v) {
              "com.mitchellh.ghostty" = "ghostty";
              "dooit/config.py" = "dooit/config.py";
            }
          )
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

            ".agent-of-empires/config.toml" = "agent-of-empires/config.toml";

            ".pi/agent/settings.json" = "pi/agent/settings.json";

            # tmux
            ".tmux.conf" = "tmux/.tmux.conf";
            ".local/bin/ra-wrapper" = "Bin/ra-wrapper";
            ".local/bin/tmux-copy" = "tmux/bin/tmux-copy";
            ".local/bin/tmux-edit-scrollback" = "tmux/bin/tmux-edit-scrollback";
            ".local/bin/tmux-help-tv" = "tmux/bin/tmux-help-tv";
            ".local/bin/tmux-scrollback-search" = "tmux/bin/tmux-scrollback-search";
            ".local/bin/tmux-sesh-tv" = "tmux/bin/tmux-sesh-tv";
            ".local/bin/tmux-session-manager-tv" = "tmux/bin/tmux-session-manager-tv";
            ".local/bin/tmux-url-picker" = "tmux/bin/tmux-url-picker";
          })
        );
      in
      (lib.mapAttrs (_: path.mkDotFile) dotfiles)
      // {
        # ensure launchd log directory exists so glance can start at login
        "Library/Logs/glance/.keep".text = "";
      };

    packages =
      with pkgs;
      [
        (bunxLatest {
          bin = "pi";
          package = "@earendil-works/pi-coding-agent";
        })
        (bunxLatest {
          bin = "svelteserver";
          # bin = "svelte-language-server";
          package = "svelte-language-server";
        })

        (pkgs.writeShellApplication {
          name = "vite-public-paths";
          text = ''
            exec ${pkgs.bun}/bin/bun ${./scripts/vite-public-paths/bin/vite-public-paths.js} "$@"
          '';
        })

        # (python313.withPackages python-packages)

        # qui
        discordo
        # zigpkgs.master
        zig.packages.${system}.nightly
        zls.packages.${system}.zls

        php85

        tmux

        (pkgs.writeShellApplication {
          name = "ns";
          runtimeInputs = with pkgs; [
            fzf
            nix-search-tv
          ];
          text = builtins.readFile "${pkgs.nix-search-tv.src}/nixpkgs.sh";
        })

        # signal-cli
        # telegram-bot-api

        ghostscript # pdf utility (ex. merge)
        clipboard-jh

        # esp
        espflash

        typst

        coreutils-full # gnu core utils

        rsync # backup & two-way sync
        # restic # efficient & secure backup
        # rustic # restic in rs

        age # encryption tool
        sops # manage secrets

        curlie # curl
        procs # ps
        sd # sed
        mprocs # run multiple commands in parallel
        nix-converter # yaml <-> nix <-> toml
        toolong # log files
        ripgrep
        # ck
        glow # preview md
        gum # shell script ui
        entr # run command on file change
        scooter # interactive search and replace
        dust # faster du
        # dua # disk usage manager tui
        dysk # better df (rs)
        # duf # better df (go)
        kondo # clean deps and build artifacts from proj

        # tldr # community man
        cht-sh # cli for cheat.sh (comprehensive cheatsheets)
        # tlrc # tldr client in rs

        # gping # ping with a graph
        dnscrypt-proxy
        # openapi-tui
        # sshs

        ## data manipulation
        jnv # interactive JSON viewer + jq filter (rs)
        fx # JSON viewer with vim bindings
        jql # query json from cli
        gojq
        yq-go # YAML, TOML, JSON and XML processor
        dasel # select/put/delete data from files
        hexyl # hex viewer
        sttr # text transformation

        # Rust Dev
        # cargo-watch
        cargo-make
        cargo-update
        cargo-binstall
        crates-tui # explore crates.io
        # dioxus-cli

        # other
        mdbook # create book from md files
        mdbook-linkcheck2 # check links
        # ttyper # terminal typing test
        # lychee # broken links checker
        # puffin # personal finance dashboard
        # bagels # tui expense tracker
        # calcure # tui calendar + task manager
        # ticker # cli stock ticker
        # sc-im # spreadsheet calculator
        # presenterm # md cli slideshow
      ]
      ++ lib.optionals stdenv.isDarwin [
        # for mac-specific packages
        m-cli # useful macOS CLI commands
      ];
  };
}

## Extras (with pkgs;) ##
# go
# go-swag # API docs
# delve # go debugger
# envsubst # env var substitution
# air # live reload for go
# pkgsite # generate docs for go
# errcheck # checks unchecked erros in go
# sqlc # generate type-safe code from SQL
# goose # db migration tool

# ghc
# ghcid
# stack # stack has own version of ghc?
# haskell-language-server
# hlint
# haskellPackages.cabal-install

# elixir_1_18
