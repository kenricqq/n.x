{
  lib,
  config,
  pkgs,
  ...
}:

{
  programs.sketchybar = {
    enable = true;
    configType = "lua";
    extraPackages = [
      pkgs.jq
    ]
    ++ lib.optional config.programs.aerospace.enable config.programs.aerospace.package;
    # config = {
    #   source = ./dotfiles/sketchybar;
    #   recursive = true;
    # };
  };

  home = {
    packages = with pkgs; [
      sketchybar-app-font
    ];
    # file = util.linkHostApp config "sketchybar";
  };
}
