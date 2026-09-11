{ dlaunch, paths, ... }:

let
  piShim = dlaunch.script "pi-shim" ''
    exec '${dlaunch.bun}' '${./pi_shim.ts}'
  '';
in
{
  serviceConfig = dlaunch.mkAgentServiceConfig {
    label = "com.ktqq.pi-shim";
    args = [ piShim ];
    workingDirectory = paths.home;
    logName = "pi-shim";
    flatLog = true;
    env = dlaunch.bunEnv // {
      PI_PACKAGE_DIR = "${paths.home}/.cache/.bun/install/global/node_modules/@earendil-works/pi-coding-agent";
    };
  };
}
