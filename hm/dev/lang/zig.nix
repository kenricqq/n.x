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
    (inputs.zls.packages.${system}.zls.overrideAttrs {
      # ZLS's zig-flake input can omit the required nightly; use our installed Zig.
      nativeBuildInputs = [ inputs.zig.packages.${system}.master ];
    })
  ];
}
