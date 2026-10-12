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

  secrets = config.home-manager.users.${machine.user}.sops.secrets;

  glance = dlaunch.script "glance-launch" ''
    set -euo pipefail
    raindrop_token_file=${lib.escapeShellArg secrets.RAINDROP_TOKEN.path}
    # launchd KeepAlive retries if sops-nix has not installed the secret yet.
    if [[ ! -r "$raindrop_token_file" ]]; then
      echo "Missing readable RAINDROP_TOKEN secret at $raindrop_token_file" >&2
      exit 1
    fi
    RAINDROP_TOKEN="$(< "$raindrop_token_file")"
    export RAINDROP_TOKEN
    exec '${pkgs.glance}/bin/glance' -config '${paths.dots}/glance/glance.yml'
  '';

  # miniflux = dlaunch.script "miniflux-launch" ''
  #   set -euo pipefail
  #   auth_key_file=${lib.escapeShellArg secrets.TS_AUTHKEY.path}
  #   TS_AUTHKEY="$(< "$auth_key_file")"
  #   export TS_AUTHKEY
  #   exec '${pkgs.golink}/bin/golink' --sqlitedb '${golinkDir}/golinks.sqlite'
  # '';

  memosDataDir = "${paths.dataHome}/memos";
  golinkDir = "${paths.nixrt}/extensions/golink";
  golink = dlaunch.script "golink-launch" ''
    set -euo pipefail
    auth_key_file=${lib.escapeShellArg secrets.TS_AUTHKEY.path}
    TS_AUTHKEY="$(< "$auth_key_file")"
    export TS_AUTHKEY
    exec '${pkgs.golink}/bin/golink' --sqlitedb '${golinkDir}/golinks.sqlite'
  '';
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
        "--data=${memosDataDir}"
        "--dsn=${memosDataDir}/memos_dev.db"
        "--port=8082"
      ];
      logName = "memos";
      flatLog = true;
    };

    # miniflux.serviceConfig = dlaunch.mkAgentServiceConfig {
    #   label = "eilmeldung.miniflux";
    #   args = [ miniflux ];
    #   logName = "miniflux";
    #   flatLog = true;
    # };

    golink.serviceConfig = dlaunch.mkAgentServiceConfig {
      label = "dev.golink";
      args = [
        golink
      ];
      workingDirectory = golinkDir;
      logName = "golink";
      flatLog = true;
    };
  };
}
