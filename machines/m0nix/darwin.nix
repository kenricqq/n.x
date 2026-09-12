{
  config,
  inputs,
  lib,
  machine,
  pkgs,
  ...
}:

let
  username = machine.user;
  userHome = "/Users/${username}";

  tb = machine.sync.tb or null;

  darwinPath = ../../os/darwin;

  system-config = import (darwinPath + "/system.nix");

  paths =
    (import ../../lib/paths.nix {
      home = config.users.users.${username}.home;
      inherit (machine) name;
    })
    // {
      configHome = config.home-manager.users.${username}.xdg.configHome;
    };

  sp = lib.concatStringsSep " ";
  val = v: if builtins.isList v then sp (map toString v) else toString v;
  nixConf = s: lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "${k} = ${val v}") s);
in
{
  _module.args = {
    inherit paths;
    inherit
      (import (darwinPath + "/helpers.nix") {
        inherit
          lib
          machine
          paths
          pkgs
          ;
      })
      dlaunch
      ;
  };

  imports = [
    inputs.nixcord.darwinModules.nixcord
  ]
  ++ map (file: darwinPath + "/${file}") [
    "homebrew.nix"
    "fonts.nix"
    "sshd.nix"
    "launchd.nix"
  ];

  environment = {
    systemPackages = with pkgs; [
      nodejs_24

      p7zip
    ];

    etc = {
      "codex/requirements.toml".source = ../../dots/codex/requirements.toml;

      "codex/hooks/agent-policy-hook.mjs".source = ../../dots/codex/agent-policy-hook.mjs;

      # Immutable copy of the Impeccable hook used by PostToolUse.
      "codex/hooks/impeccable".source = ../../dots/AI/skills/impeccable;

      # Stable interpreter path usable from requirements.toml.
      "codex/bin/node".source = "${pkgs.nodejs_22}/bin/node";
    };
  };

  # Host basics
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
    hostPlatform = {
      system = "aarch64-darwin";
    };
  };

  # Create /etc/bashrc that loads the nix-darwin environment.
  # services.nix-daemon.enable = true;
  users.users.${username} = {
    home = userHome;
    uid = 501;
  };

  # Determinate Nix owns /etc/nix/nix.conf and the daemon.
  # nix-darwin owns only included custom file below.
  nix.enable = false;

  environment.etc."nix/nix.custom.conf".text = ''
    # Managed by nix-darwin. Included from Determinate Nix /etc/nix/nix.conf.
    ${nixConf {
      # eval-cores = 0;
      trusted-users = [
        "root"
        machine.user
      ];
      extra-substituters = [
        "https://devenv.cachix.org"
        "https://helix.cachix.org"
        "https://fenix.cachix.org"

        "https://comfyui.cachix.org"
        "https://nix-community.cachix.org"
        # "https://cuda-maintainers.cachix.org"
        "https://cache.nixos-cuda.org"
        "https://adithyagenie.cachix.org" # blender cuda

        "https://zig-overlay.cachix.org"
        "https://zigtools.cachix.org"
        "https://codex-desktop-linux.cachix.org"
        "https://jj.cachix.org"
        "https://oxalica.cachix.org"
      ];
      extra-trusted-public-keys = [
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
        "fenix.cachix.org-1:ecJhr+RdYEdcVgUkjruiYhjbBloIEGov7bos90cZi0Q="

        "comfyui.cachix.org-1:33mf9VzoIjzVbp0zwj+fT51HG0y31ZTK3nzYZAX0rec="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        # "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        "adithyagenie.cachix.org-1:h6BSMboeVfxyrULWuRQqAyweo4AJRATekb88xotfQwc="

        "zig-overlay.cachix.org-1:MCS36+WBxE8vqfE4j5BnCAx0Gse9EnTLSukAvP8JwtA="
        "zigtools.cachix.org-1:USl8MDuq1Jyx4pET+Q8siEIf1Nfja7hyXr9NuOf12PU="
        "codex-desktop-linux.cachix.org-1:nX/xy6AdK9hQE24A8ALGjkCKj2ObFmcnemiL5Cid4nk="
        "jj.cachix.org-1:rOXYMWIM8CAjR0M3kifWXVoDXVriTPz+gX5oSdJe2Is="
        "oxalica.cachix.org-1:h0iRBw6tQD8+51ZvnNEBPbwLR58UD7klauDBWzBdugQ="
      ];
    }}
  '';

  services = {
    postgresql = {
      enable = true;
      enableTCPIP = true;
      package = pkgs.postgresql_18;
      port = 5433;
      # ensureDatabases = [
      #   "miniflux"
      #   "postgres"
      # ];
      # ensureUsers = [
      #   {
      #     name = "miniflux";
      #     ensurePermissions = {
      #       "DATABASE miniflux" = "ALL PRIVILEGES";
      #     };
      #   }
      #   {
      #     name = "superuser";
      #     ensurePermissions = {
      #       "ALL TABLES IN SCHEMA public" = "ALL PRIVILEGES";
      #     };
      #   }
      # ];
      extraPlugins = with pkgs.postgresql18Packages; [
        pg_cron
      ];
      settings = {
        log_connections = true;
        log_statement = "all";
        logging_collector = true;
        log_disconnections = true;
        log_destination = lib.mkForce "syslog";
      };
    };
  };

  system = lib.recursiveUpdate system-config {
    primaryUser = username;

    activationScripts.postActivation.text = lib.mkAfter ''
      if launchctl print system/systems.determinate.nix-daemon >/dev/null 2>&1; then
        launchctl kickstart -k system/systems.determinate.nix-daemon || true
      fi

      ${lib.optionalString (tb != null) ''
        SERVICE="Thunderbolt Bridge"
        IP=${lib.escapeShellArg tb}
        MASK="255.255.255.0"
        ROUTER="0.0.0.0"

        if /usr/sbin/networksetup -listallnetworkservices \
          | /usr/bin/grep -Fxq "$SERVICE"; then
          /usr/sbin/networksetup -setmanual \
            "$SERVICE" "$IP" "$MASK" "$ROUTER"
        else
          echo "Skipping Thunderbolt setup: $SERVICE not found"
        fi
      ''}
    '';
  };

  time.timeZone = "America/Los_Angeles";
}
