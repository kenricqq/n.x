{ pkgs, ... }:

let
  user = "YOUR_USERNAME";
  home = "/home/${user}";
in
{
  # Provides npm + bun.
  environment.systemPackages = with pkgs; [
    nodejs
    bun
    git
  ];

  # So ~/.local/bin/codex is available normally.
  environment.localBinInPath = true;

  # ──────────────────────────────────────────────
  # Codex
  # ──────────────────────────────────────────────

  systemd.services.update-codex = {
    description = "Update OpenAI Codex CLI";

    path = with pkgs; [
      nodejs
      coreutils
    ];

    serviceConfig = {
      Type = "oneshot";
      User = user;
      WorkingDirectory = home;
      Environment = [
        "HOME=${home}"
      ];
    };

    script = ''
      set -euo pipefail

      mkdir -p "$HOME/.local"

      npm install \
        --global \
        --prefix "$HOME/.local" \
        @openai/codex@latest

      "$HOME/.local/bin/codex" --version
    '';
  };

  systemd.timers.update-codex = {
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnCalendar = "*-*-* 03:00:00";
      Persistent = true;
      RandomizedDelaySec = "20m";
      Unit = "update-codex.service";
    };
  };

  # ──────────────────────────────────────────────
  # Agent Skills
  # ──────────────────────────────────────────────

  systemd.services.update-agent-skills = {
    description = "Update installed Agent Skills";

    path = with pkgs; [
      bun
      git
      coreutils
    ];

    serviceConfig = {
      Type = "oneshot";
      User = user;
      WorkingDirectory = home;
      Environment = [
        "HOME=${home}"
      ];
    };

    script = ''
      set -euo pipefail

      bunx --bun skills@latest update -g -y
    '';
  };

  systemd.timers.update-agent-skills = {
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnCalendar = "*-*-* 03:30:00";
      Persistent = true;
      RandomizedDelaySec = "20m";
      Unit = "update-agent-skills.service";
    };
  };
}
