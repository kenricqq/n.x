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
        just
        glow
      ]
      ++ lib.optionals isLinux [
        handy
        wtype # needed for handy

        comfyui
      ];

    sessionPath =
      (map (f: "${paths.home}/${f}") [
        ".cargo/bin"
        ".local/bin"
        ".nix-profile/bin"
        "go/bin"
        ".bun/bin"
        ".cache/.bun/bin"
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
      # SNIPPETS_PATH = path.snippets; # for scls
      # SHARE = path.share;

      # NODE_PATH = "${home}/.cache/.bun/install/global/node_modules";

      EDITOR = "hx";
      VISUAL = "hx";
      PAGER = "less -R";
      LANG = "en_US.UTF-8";

      # }
      # // lib.optionalAttrs isDarwin {
      # DARWIN_HOST = hostName;
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

            #   ".agent-of-empires/config.toml" = "agent-of-empires/config.toml";
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
