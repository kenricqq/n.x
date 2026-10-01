{
  config,
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
    isNixos
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
    ./zen.nix

    ./sync.nix # restic/rsync/syncthing

    ./nushell.nix
    ./zsh.nix

    ./diagnostics.nix
    ./file-tools.nix
    ./nix-tools.nix

    ./display.nix
    ./navigation.nix
    ./media.nix
    ./misc/extras.nix
    ./security.nix # age/sops/gpg
    ./ssh.nix
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

        python314Packages.kokoro
        signal-cli
      ]
      ++ lib.optionals (isLinux || isNixos) [
        handy
        wtype # needed for handy

        comfyui

        loupe
        swayimg
      ]
      ++ lib.optionals isDarwin [
        m-cli # useful macOS CLI commands
        nightlight # night shift cli
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

        "/Applications/ChatGPT.app/Contents/Resources/cua_node/bin"
      ]
      ++ lib.optionals (isLinux || isNixos) [
        # Follow HM's profile directory for standalone and OS-managed packages.
        "${config.home.profileDirectory}/opt/codex-desktop/resources/cua_node/bin"
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

      PI_CODING_AGENT_DIR = "${config.xdg.configHome}/pi/agent";

      # }
      # // lib.optionalAttrs isDarwin {
      # DARWIN_HOST = hostName;
      # LIBCLANG_PATH = "${home}/.rustup/toolchains/esp/xtensa-esp32-elf-clang/esp-20.1.1_20250829/esp-clang/lib";
      # DYLD_FALLBACK_LIBRARY_PATH = "/opt/homebrew/lib";
    };

    file =
      lib.mapAttrs (_: paths.mkDotFile) {
        ".agents/skills" = "AI/skills";
        ".codex/AGENTS.md" = "AI/AGENTS.md";
        ".codex/prompts" = "codex/prompts";
        ".codex/skills" = "codex/skills";
        ".codex/automations" = "codex/automations";
        ".codex/config.toml" = "codex/config.toml";
        ".codex/agent.config.toml" = "codex/agent.config.toml";
        ".codex/deep-review.config.toml" = "codex/deep-review.config.toml";
        ".codex/keybindings.json" = "codex/keybindings.json";
        ".codex/hooks.json" = "codex/hooks.json";

        ".hermes/SOUL.md" = "hermes/SOUL.md";
      }
      // lib.optionalAttrs isDarwin {
        "Library/Application Support/dooit/config.py" = paths.mkDotFile "dooit/config.py";
        # ensure launchd log directory exists so glance can start at login
        "Library/Logs/glance/.keep".text = "";
      }
      // lib.optionalAttrs (isLinux || isNixos) {
        ".local/bin/inir" = paths.mkDotFile "quickshell/inir/scripts/inir";
        ".local/share/com.pais.handy/settings_store.json" = paths.mkDotFile "handy/settings_store.json";
      };
  };

  xdg.configFile = lib.mapAttrs (_: paths.mkDotFile) (
    {
      "yazi/flavors" = "yazi/flavors";
      "hunk" = "hunk";
      "jj/config.toml" = "jj/config.toml";
      "niri" = "niri";
      "nushell/modules" = "nushell/modules";
      "ghostty" = "ghostty";

      "zed/keymap.json" = "zed/keymap.json";
      "zed/settings.json" = "zed/settings.json";
    }
    // lib.optionalAttrs isDarwin {
      "aerospace" = "aerospace";
      "sketchybar" = "sketchybar";
    }
    // lib.optionalAttrs (isLinux || isNixos) {
      "autostart/handy.desktop" = "handy/handy.desktop";
      "quickshell" = "quickshell";
      "inir" = "inir";
    }
  );
}
