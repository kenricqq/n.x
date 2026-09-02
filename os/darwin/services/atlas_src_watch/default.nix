{ lib, pkgs, ... }:

let
  inherit (import ../../paths.nix { inherit lib pkgs; }) dpath dlaunch;

  atlasRoot = "${dpath.home}/KTQQ/docs/Ideaverse/Atlas";
  piCli = "${dpath.home}/.cache/.bun/install/global/node_modules/@earendil-works/pi-coding-agent/dist/cli.js";

  atlasWatch = dlaunch.script "atlas-src-watch" ''
    exec '${dlaunch.bun}' '${./atlas_src_watch.ts}'
  '';
in
{
  serviceConfig = dlaunch.mkAgentServiceConfig {
    label = "wiki.atlas_src_watch";
    args = [ atlasWatch ];
    workingDirectory = atlasRoot;
    logName = "atlas_src_watch";
    flatLog = true;
    env = dlaunch.bunEnv // {
      ATLAS_SRC_WATCH_ROOT = atlasRoot;
      ATLAS_SRC_WATCH_PI_COMMAND_JSON = ''["${dlaunch.bun}","${piCli}"]'';
      ATLAS_SRC_WATCH_OPEN_COMMAND_JSON = ''["/usr/bin/open"]'';
      ATLAS_SRC_WATCH_CONCURRENCY = "1";
      ATLAS_SRC_WATCH_POLL_MS = "10000";
      ATLAS_SRC_WATCH_STABLE_MS = "3000";
    };
  };
}
