{ lib, pkgs, ... }:

let
  inherit (import ./helpers.nix { inherit lib pkgs; }) dpath dlaunch;

  # piShim = import ./services/pi-shim { inherit lib pkgs; };
  # atlasSrcWatch = import ./services/atlas_src_watch { inherit lib pkgs; };

  glance = dlaunch.script "glance-launch" ''
    set -euo pipefail
    source "$HOME/.cache/zsh/secrets.env"
    exec '${pkgs.glance}/bin/glance' -config '${dpath.dot}/glance/glance.yml'
  '';

  miniflux = dlaunch.script "miniflux-launch" ''
    set -euo pipefail
    until '${pkgs.postgresql_18}/bin/pg_isready' -h 127.0.0.1 -p 5433 >/dev/null 2>&1; do sleep 1; done
    exec '${pkgs.miniflux}/bin/miniflux' -c '${dpath.dot}/miniflux/config.env'
  '';

  golinkDir = "${dpath.repo}/extensions/golink";
  logDirs = [
    "glance"
    "miniflux"
    "memos"
    "golink"
  ];
in
{
  launchd.user.agents = {
    # Source-backed services keep their serviceConfig beside their code.
    # "pi-shim".serviceConfig = piShim.serviceConfig;
    # atlas_src_watch.serviceConfig = atlasSrcWatch.serviceConfig;

    # Package-backed services stay fully visible here.
    glance.serviceConfig = dlaunch.mkAgentServiceConfig {
      label = "dev.glance";
      args = [ glance ];
      logName = "glance";
      flatLog = true;
    };

    memos.serviceConfig = dlaunch.mkAgentServiceConfig {
      label = "dev.memos";
      args = [
        "${pkgs.memos}/bin/memos"
        "--data=${dpath.home}/KTQQ/docs/notes/memos"
        "--port=8082"
      ];
      logName = "memos";
    };

    miniflux.serviceConfig = dlaunch.mkAgentServiceConfig {
      label = "eilmeldung.miniflux";
      args = [ miniflux ];
      logName = "miniflux";
    };

    golink.serviceConfig = dlaunch.mkAgentServiceConfig {
      label = "dev.golink";
      args = [
        "${pkgs.golink}/bin/golink"
        "--sqlitedb"
        "${golinkDir}/golinks.sqlite"
      ];
      workingDirectory = golinkDir;
      logName = "golink";
    };
  };

  system.activationScripts.postActivation.text = lib.mkAfter (dlaunch.mkLogDirs logDirs);
}
