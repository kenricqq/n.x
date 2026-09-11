{ config, pkgs, ... }:

let
  toggleGap = pkgs.writeShellApplication {
    name = "toggle-sketchybar-gap";
    runtimeInputs = [
      pkgs.python3
      config.programs.sketchybar.package
    ];
    text = builtins.readFile ../../scripts/toggle-sketchybar-gap.sh;
  };
in
{
  home.packages = [ toggleGap ];

  programs.aerospace = {
    enable = true;
    launchd = {
      # enable = true;
      # keepAlive = true;
    };
  };
}
