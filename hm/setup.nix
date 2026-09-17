{
  lib,
  host,
  pkgs,
  ...
}:

let
  inherit (host)
    isDarwin
    isLinux
    isNixos
    ;

  ## -- Arch System Packages -- ##

  nixCaches = import ../os/shared/nix-caches.nix;

  system-packages = [
    "bun"
    "cronie"
    "tailscale"
    "podman"
    "smartmontools"
    "ddcutil"
    "brightnessctl"

    "python-ytmusicapi"
    # "pacman-contrib"

    "freecad"
  ];

  arch-install = pkgs.writeShellApplication {
    name = "arch-install";

    text = ''
      # Share caches with NixOS and nix-darwin, preserving existing Nix settings.
      sudo tee /etc/nix/shared-caches.conf > /dev/null <<'EOF'
      extra-substituters = ${lib.concatStringsSep " " nixCaches.substituters}
      extra-trusted-public-keys = ${lib.concatStringsSep " " nixCaches.trusted-public-keys}
      EOF
      if ! sudo grep -Fxq '!include shared-caches.conf' /etc/nix/nix.conf; then
        printf '\n!include shared-caches.conf\n' | sudo tee -a /etc/nix/nix.conf > /dev/null
      fi
      sudo systemctl try-restart nix-daemon.service

      sudo pacman -S --needed ${lib.escapeShellArgs system-packages}

      # activate tailscale
      sudo systemctl enable --now tailscaled

      # hermes desktop
      curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
    '';
  };

  ## -- Bun Global Packages -- ##

  bun-packages = [
    "@earendil-works/pi-coding-agent"
    "@openai/codex"
    "opencode-ai@latest"

    "svelte-language-server"

    "oxlint-tsgolint@latest"
    "oxfmt@latest"
  ];

  skills = [
    "mattpocock/skills"
    "emilkowalski/skills"
    "jakubkrehel/skills"

    # "huntabyte/shadcn-svelte"
    # "sveltejs/ai-tools"
    # "paradedb/agent-skills"
    # "JuliusBrussee/caveman"
    # "humanlayer/skills"
  ];

  bun-install = pkgs.writeShellApplication {
    name = "bun-install";

    text = ''
      bun add -g ${lib.escapeShellArgs bun-packages}

      bunx impeccable@latest install --scope=global

      for skill_repo in ${lib.escapeShellArgs skills}; do
        bunx skills@latest add "$skill_repo" --global
      done
    '';
  };

  ## -- Updates -- ##

  arch-update = pkgs.writeShellApplication {
    name = "arch-update";

    text = ''
      echo "Updating Arch packages"
      sudo pacman -Syu

      echo "Removing orphaned packages"
      mapfile -t orphans < <(pacman -Qdtq || true)
      if (( ''${#orphans[@]} > 0 )); then
        sudo pacman -Rns "''${orphans[@]}"
      fi

      echo "Cleaning old package cache"
      sudo paccache -r
      sudo paccache -ruk0
    '';
  };

  bun-update = pkgs.writeShellApplication {
    name = "bun-update";

    text = ''
      echo "Updating Bun packages"
      bun update -g --latest
      bunx impeccable@latest update --user
      bunx skills@latest update -g -y

      pi update --extensions
    '';
  };
in
{
  home.packages = [
    bun-install
    bun-update
  ]
  ++ lib.optionals isLinux [
    arch-install
    arch-update
  ];
}
