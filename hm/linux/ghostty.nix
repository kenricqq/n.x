{ config, paths, pkgs, ... }:

let
  inherit (paths)
    home
  ;
in
{
  programs.ghostty = {
    enable = true;
    installVimSyntax = true;
  };
}
