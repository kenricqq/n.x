{ pkgs, ... }:

{
  home.packages = with pkgs; [
    oxvg
  ];
}
