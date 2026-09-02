{ config, paths, pkgs, ... }:

let
  inherit (paths)
    home
  ;
in
{
  programs.obsidian = {
    enable = true;
    cli.enable = true;
    defaultSettings = {
      corePlugins = {
        
      };
      communityPlugins = {
      
      };
    };
  };
}
