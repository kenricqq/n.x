{
  config,
  dlaunch,
  lib,
  machine,
  paths,
  pkgs,
  ...
}:

let
  # piShim = import ./services/pi-shim { inherit dlaunch paths; };
  # atlasSrcWatch = import ./services/atlas_src_watch { inherit dlaunch paths; };

  glance = dlaunch.script "glance-launch" ''
    set -euo pipefail
    raindrop_token_file=${lib.escapeShellArg config.home-manager.users.${machine.user}.sops.secrets.RAINDROP_TOKEN.path}
    # launchd KeepAlive retries if sops-nix has not installed the secret yet.
    if [[ ! -r "$raindrop_token_file" ]]; then
      echo "Missing readable RAINDROP_TOKEN secret at $raindrop_token_file" >&2
      exit 1
    fi
    RAINDROP_TOKEN="$(< "$raindrop_token_file")"
    export RAINDROP_TOKEN
    exec '${pkgs.glance}/bin/glance' -config '${paths.dots}/glance/glance.yml'
  '';

  miniflux = dlaunch.script "miniflux-launch" ''
    set -euo pipefail
    until '${pkgs.postgresql_18}/bin/pg_isready' -h 127.0.0.1 -p 5433 >/dev/null 2>&1; do sleep 1; done
    exec '${pkgs.miniflux}/bin/miniflux' -c '${paths.dots}/miniflux/config.env'
  '';

  golinkDir = "${paths.nixrt}/extensions/golink";
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
        "--data=${paths.home}/KTQQ/docs/notes/memos"
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
