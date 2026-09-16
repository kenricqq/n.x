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
  ];

  arch-install = pkgs.writeShellApplication {
    name = "arch-install";

    text = ''
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
