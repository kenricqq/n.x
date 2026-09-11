{ paths, ... }:

let
  inherit (paths) home;
in
{
  programs.ssh = {
    enable = false;
    enableDefaultConfig = false;
    includes = [
      "~/.ssh/config.local"
    ];
  };
}
