{
  inputs,
  machine,
  pkgs,
  ...
}:

{
  imports = [
    inputs.codex-desktop-linux.homeManagerModules.default

    ./linux/chinese.nix

    ./linux/codex-desktop.nix
    ./linux/ghostty.nix
    ./linux/niri.nix
    ./linux/obsidian.nix
    ./linux/zed.nix
    # ./linux/zen.nix
  ];

  home = {
    packages = with pkgs; [
      # gui apps
      vicinae # raycast-like
      zathura # pdf viewer
      obsidian
      vlc
      jellyfin-desktop

      # browser
      inputs.helium.packages.${machine.system}.default
      google-chrome

      proton-vpn
      proton-pass

      # monitoring
      nvitop # nvidia gpu monitoring
      openrgb # gpu lighting
      mangohud # system monitor overlay

      # dev
      # beekeeper-studio
      podman-desktop
      yaak

      # optional gui apps
      nautilus # file manager

      # non-gui packages
      librepods
    ];
  };
}
