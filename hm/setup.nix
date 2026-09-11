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

      ## append to end?
      # trusted-users = root kenrict
      # extra-substituters = https://devenv.cachix.org https://helix.cachix.org https://fenix.cachix.org
      # extra-trusted-public-keys = devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw= helix.cachix.or g-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs= fenix.cachix.org-1:ecJhr+RdYEdcVgUkjruiYhjbBloIEGov7bos90cZ i0Q=
    '';
  };

  ## -- Bun Global Packages -- ##

  bun-packages = [
    "@earendil-works/pi-coding-agent"
    "@openai/codex"
    "opencode-ai@latest"

    "svelte-language-server"
  ];

  skills = [
    "mattpocock/skills"
    "emilkowalski/skills"
    "pbakaus/impeccable"

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

      bunx skills@latest add ${lib.escapeShellArgs skills}
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
      bunx skills@latest update -g -y
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
