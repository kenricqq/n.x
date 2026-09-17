{ lib, machine }:

let
  platform = lib.systems.elaborate machine.system;
in
{
  isDarwin = platform.isDarwin;
  isLinux = platform.isLinux && !(machine.nixos or false); # non-NixOS Linux
  isNixos = machine.nixos or false;
  isWsl = machine.wsl or false;
}
