{ lib, pkgs, ... }:

let
  inherit (import ../../paths.nix { inherit lib pkgs; }) dpath dlaunch;

  piShim = dlaunch.script "pi-shim" ''
    exec '${dlaunch.bun}' '${./pi_shim.ts}'
  '';
in
{
  serviceConfig = dlaunch.mkAgentServiceConfig {
    label = "com.ktqq.pi-shim";
    args = [ piShim ];
    workingDirectory = dpath.home;
    logName = "pi-shim";
    flatLog = true;
    env = dlaunch.bunEnv // {
      PI_PACKAGE_DIR = "${dpath.home}/.cache/.bun/install/global/node_modules/@earendil-works/pi-coding-agent";
    };
  };
}
