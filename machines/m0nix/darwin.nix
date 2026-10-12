{
  inputs,
  lib,
  machine,
  paths,
  pkgs,
  ...
}:

let
  username = machine.user;
  userHome = "/Users/${username}";

  tb = machine.network.tb or null;

  darwinPath = ../../os/darwin;

  system-config = import (darwinPath + "/system.nix");
  nixCaches = import ../nix-caches.nix;

  sp = lib.concatStringsSep " ";
  val = v: if builtins.isList v then sp (map toString v) else toString v;
  nixConf = s: lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "${k} = ${val v}") s);
in
{
  _module.args = {
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
    inputs.nix-plist-manager.darwinModules.default
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

      # Preserve the JavaScript hook expected by agent-policy-hook.mjs.
      "codex/hooks/impeccable".source = ../../dots/codex/hooks/impeccable;

      # Stable interpreter path usable from requirements.toml.
      "codex/bin/node".source = "${pkgs.nodejs_22}/bin/node";
    };
  };

  # Host basics; lib/mksystem.nix sets allowUnfree for every system.
  nixpkgs.hostPlatform.system = "aarch64-darwin";

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
      extra-substituters = nixCaches.substituters;
      extra-trusted-public-keys = nixCaches.trusted-public-keys;
    }}
  '';

  services = {
    postgresql = {
      enable = true;
      enableTCPIP = true;
      package = pkgs.postgresql_18;
      dataDir = "${paths.nixrt}/extensions/postgresql/18";
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

  # lib/mksystem.nix sets system.primaryUser and stateVersion.
  system = lib.recursiveUpdate system-config {
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

  programs.nix-plist-manager = {
    enable = true;
    # Optional machine settings; uncomment only the ones you want managed.
    options.applications.systemSettings = {
      # network.firewall.firewall = true;
      # network.firewall.options.enableStealthMode = true;
      # general.softwareUpdate.automaticallyDownloadNewUpdatesWhenAvailable = true;
      # general.softwareUpdate.automaticallyInstallMacOSUpdates = false;
      # general.softwareUpdate.automaticallyInstallSystemDataFilesAndSecurityUpdates = true;
      # lockScreen.turnDisplayOffOnBatteryWhenInactive = "For 5 minutes";
      # lockScreen.turnDisplayOffOnPowerAdapterWhenInactive = "For 10 minutes";
      # lockScreen.showPasswordHints = false;
      # lockScreen.loginWindowShows = "Name and password";
    };
  };
}
