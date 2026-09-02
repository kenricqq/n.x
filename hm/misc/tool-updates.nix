{ config, lib, pkgs, ... }:

let
  home = config.home.homeDirectory;

  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  # Put globally installed Bun executables somewhere generic.
  #
  # The actual packages still live in Bun's default:
  #   ~/.bun/install/global
  #
  # Only the executable links go here:
  globalBin = "${home}/.local/bin";

  logDir = "${home}/.local/state/dev-tool-updates";

  updateCodex = pkgs.writeShellApplication {
    name = "update-codex";

    runtimeInputs = with pkgs; [
      bun
      nodejs
      coreutils
    ];

    text = ''
      export HOME=${lib.escapeShellArg home}

      # Bun normally uses ~/.bun/bin.
      # Keep executables in ~/.local/bin instead.
      export BUN_INSTALL_BIN=${lib.escapeShellArg globalBin}

      mkdir -p "$BUN_INSTALL_BIN"

      echo "Updating Codex..."

      bun install --global @openai/codex@latest

      echo
      echo "Installed:"
      "$BUN_INSTALL_BIN/codex" --version
    '';
  };

  updateSkills = pkgs.writeShellApplication {
    name = "update-skills";

    runtimeInputs = with pkgs; [
      bun
      git
      coreutils
    ];

    text = ''
      export HOME=${lib.escapeShellArg home}

      echo "Updating Agent Skills..."

      bunx --bun skills@latest update -g -y
    '';
  };
in

lib.mkMerge [
  # ─────────────────────────────────────────────
  # Shared: Linux + macOS
  # ─────────────────────────────────────────────

  {
    home.packages = [
      pkgs.bun

      # Still needed by @openai/codex's JS launcher.
      pkgs.nodejs

      # Lets you manually run:
      #
      #   update-codex
      #   update-skills
      updateCodex
      updateSkills
    ];

    home.sessionPath = [
      globalBin
    ];

    # Ensures the log directory exists before launchd
    # tries to open files inside it.
    home.file.".local/state/dev-tool-updates/.keep".text = "";
  }

  # ─────────────────────────────────────────────
  # Linux: NixOS + CachyOS
  # ─────────────────────────────────────────────

  (lib.mkIf isLinux {
    systemd.user.services.update-codex = {
      Unit = {
        Description = "Update OpenAI Codex CLI";
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${updateCodex}/bin/update-codex";
        WorkingDirectory = home;
      };
    };

    systemd.user.timers.update-codex = {
      Unit = {
        Description = "Nightly OpenAI Codex update";
      };

      Timer = {
        OnCalendar = "*-*-* 03:00:00";
        Persistent = true;
        RandomizedDelaySec = "10m";
      };

      Install = {
        WantedBy = [ "timers.target" ];
      };
    };


    systemd.user.services.update-skills = {
      Unit = {
        Description = "Update Agent Skills";
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${updateSkills}/bin/update-skills";
        WorkingDirectory = home;
      };
    };

    systemd.user.timers.update-skills = {
      Unit = {
        Description = "Nightly Agent Skills update";
      };

      Timer = {
        OnCalendar = "*-*-* 03:20:00";
        Persistent = true;
        RandomizedDelaySec = "10m";
      };

      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  })

  # ─────────────────────────────────────────────
  # macOS
  # ─────────────────────────────────────────────

  (lib.mkIf isDarwin {
    launchd.agents.update-codex = {
      enable = true;
      domain = "user";

      config = {
        ProgramArguments = [
          "${updateCodex}/bin/update-codex"
        ];

        WorkingDirectory = home;
        ProcessType = "Background";

        StartCalendarInterval = {
          Hour = 3;
          Minute = 0;
        };

        EnvironmentVariables = {
          HOME = home;
        };

        StandardOutPath = "${logDir}/codex.log";
        StandardErrorPath = "${logDir}/codex.err";
      };
    };

    launchd.agents.update-skills = {
      enable = true;
      domain = "user";

      config = {
        ProgramArguments = [
          "${updateSkills}/bin/update-skills"
        ];

        WorkingDirectory = home;
        ProcessType = "Background";

        StartCalendarInterval = {
          Hour = 3;
          Minute = 20;
        };

        EnvironmentVariables = {
          HOME = home;
        };

        StandardOutPath = "${logDir}/skills.log";
        StandardErrorPath = "${logDir}/skills.err";
      };
    };
  })
]
