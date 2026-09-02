{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Essential packages
  home.packages = with pkgs; [
    # System utilities
    htop
    btop
    curl
    wget
    unzip
    tree
    jq

    # Modern CLI tools
    delta # Better git diff
    tokei # Code statistics
    bottom # System monitor
    dust # Disk usage analyzer
    procs # Better ps
    lazygit # Git TUI

    # to get greetd working
    meson
    gcc
    just

    greetd
    dbus

    wayland
    wayland-protocols
    wlroots_0_20

    libglvnd
    freetype
    fontconfig

    cairo
    pango
    harfbuzz

    libxkbcommon
    glib

    tomlplusplus
    nlohmann_json
    stb

    libwebp
    librsvg
  ];
}
