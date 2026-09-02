{
  inputs,
  machine,
  pkgs,
  ...
}:
let
  inherit (machine)
    system
    ;
in
{
  home.packages = [
    inputs.zig.packages.${system}.master
    inputs.zls.packages.${system}.zls
  ];
}
