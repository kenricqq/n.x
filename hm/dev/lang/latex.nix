{ pkgs, ... }:

{
  home.packages = with pkgs; [
    tectonic
    texlab
    tex-fmt
  ];
}
