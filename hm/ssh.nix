{ ... }:

{
  programs.ssh = {
    enable = false;
    enableDefaultConfig = false;
    includes = [
      "~/.ssh/config.local"
    ];
  };
}
