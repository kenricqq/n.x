{ paths, ... }:

let
  inherit (paths) home;
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [
      "~/.ssh/config"
    ];
  };
}
