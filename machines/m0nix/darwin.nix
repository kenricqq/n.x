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
      "nix-darwin/privacy-check.ts".source = ../../scripts/privacy-check.ts;

      # Install manually through System Settings; activation only writes the file.
      "nix-darwin/privacy-restrictions.mobileconfig".text = lib.generators.toPlist { escape = true; } {
        PayloadType = "Configuration";
        PayloadVersion = 1;
        PayloadIdentifier = "local.m0nix.privacy-restrictions";
        PayloadUUID = "5499F224-571C-4E37-AD40-68D582797565";
        PayloadDisplayName = "m0nix Privacy Restrictions";
        PayloadDescription = "Disable selected Apple Intelligence features and model downloads, Game Center, Spotlight internet results, Apple Music, and the Book Store.";
        PayloadScope = "System";
        PayloadContent = [
          {
            PayloadType = "com.apple.applicationaccess";
            PayloadVersion = 1;
            PayloadIdentifier = "local.m0nix.privacy-restrictions.applicationaccess";
            PayloadUUID = "7DB1AF13-B724-4EA7-A914-7E0DB763FE07";
            PayloadDisplayName = "Apple Service Restrictions";
            allowAssistant = false;
            allowBookstore = false;
            allowExternalIntelligenceIntegrations = false;
            allowExternalIntelligenceIntegrationsSignIn = false;
            allowGameCenter = false;
            allowGenmoji = false;
            allowImagePlayground = false;
            allowMailSmartReplies = false;
            allowMailSummary = false;
            allowMusicService = false;
            allowNotesTranscriptionSummary = false;
            allowSafariSummary = false;
            allowSpotlightInternetResults = false;
            allowWritingTools = false;
          }
        ]
        # macOS accepts only one preference domain per managed-preferences payload.
        ++
          lib.mapAttrsToList
            (domain: settings: {
              PayloadType = "com.apple.ManagedClient.preferences";
              PayloadVersion = 1;
              PayloadIdentifier = "local.m0nix.privacy-restrictions.preferences.${domain}";
              PayloadUUID = settings.uuid;
              PayloadDisplayName = "Apple Intelligence Preferences: ${domain}";
              PayloadContent.${domain}.Forced = [
                { mcx_preference_settings = settings.preferences; }
              ];
            })
            {
              ".GlobalPreferences" = {
                uuid = "2A8CFA7E-ECAB-4A1F-8E12-6AD34483DE40";
                preferences.NSAutomaticInlinePredictionEnabled = false;
              };
              "com.apple.MobileAsset" = {
                uuid = "02D19164-F487-4105-B5CC-83B446515A4F";
                # Match RemoveMacAI's download blocks; this local URL needs no app or server.
                preferences = lib.genAttrs [
                  "DownloadServerBaseURLOverride-com.apple.MobileAsset.UAF.FM.CodeLM"
                  "DownloadServerBaseURLOverride-com.apple.MobileAsset.UAF.FM.GenerativeModels"
                  "DownloadServerBaseURLOverride-com.apple.MobileAsset.UAF.FM.Visual"
                  "DownloadServerBaseURLOverride-com.apple.MobileAsset.UAF.Photos.MagicCleanup"
                  "DownloadServerBaseURLOverride-com.apple.MobileAsset.UAF.Photos.SpatialPhotosRelive"
                ] (_: "https://127.0.0.1:9/removemacai-blocked/");
              };
              "com.apple.MobileSMS" = {
                uuid = "42F562E2-AC5D-4891-8CBB-DB25DD51351E";
                preferences.messageSummarizationEnabled = false;
              };
              "com.apple.Siri" = {
                uuid = "D4919E8B-742E-4DA7-AAE2-00A9100B8726";
                preferences = {
                  StatusMenuVisible = false;
                  VoiceTriggerUserEnabled = false;
                };
              };
              "com.apple.assistant.support" = {
                uuid = "2EB210F3-5620-4749-A091-214760A54B47";
                preferences."Assistant Enabled" = false;
              };
              "com.apple.spatialphotosrelive" = {
                uuid = "17D71C29-D272-4F82-B9B2-7BB025E95892";
                preferences.LocallyDisabled = true;
              };
              "group.com.apple.mail" = {
                uuid = "2AB1BABC-F6F4-4D6C-A854-BE8FB00EAD68";
                preferences = {
                  DisableAutomaticMessageSummarization = true;
                  PersonalizedSmartReplies = false;
                };
              };
              "group.com.apple.usernoted" = {
                uuid = "8B8420B1-72D1-412F-B230-565A670C991D";
                preferences.summarize_previews = false;
              };
            };
      };

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
    defaults.CustomUserPreferences = {
      # Photos keeps a separate sandbox copy of this preference.
      "com.apple.photos.shareddefaults".IPXDefaultEnhancedVisualSearchEnabled = false;
      "${userHome}/Library/Containers/com.apple.Photos/Data/Library/Preferences/com.apple.photos.shareddefaults".IPXDefaultEnhancedVisualSearchEnabled =
        false;
    };

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
    options.applications.systemSettings = {
      privacyAndSecurity.analyticsAndImprovements.shareMacAnalytics = false;

      # Optional machine settings; uncomment only the ones you want managed.
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
