{
  lib,
  machine,
  paths,
  pkgs,
}:

let
  inherit (lib) concatMapStringsSep concatStringsSep;

  dlaunch = rec {
    script = name: text: "${pkgs.writeShellScriptBin name text}/bin/${name}";

    bun = "${pkgs.bun}/bin/bun";
    bunPath = concatStringsSep ":" [
      "${pkgs.bun}/bin"
      "${paths.home}/.cache/.bun/bin"
      "${paths.home}/.bun/bin"
      "/run/current-system/sw/bin"
      "/etc/profiles/per-user/${machine.user}/bin"
      "/nix/var/nix/profiles/default/bin"
      "/opt/homebrew/bin"
      "/usr/local/bin"
      "/usr/bin"
      "/bin"
      "/usr/sbin"
      "/sbin"
    ];

    bunEnv = {
      BUN_INSTALL = "${paths.home}/.cache/.bun";
      PATH = bunPath;
    };

    logDir = name: "${paths.home}/Library/Logs/${name}";
    logBase = name: flat: if flat then logDir name else "${logDir name}/${name}";

    mkLogDirs =
      names:
      concatMapStringsSep "\n" (
        name: "install -d -m 755 -o ${machine.user} -g staff '${logDir name}'"
      ) names;

    mkAgentServiceConfig =
      {
        label,
        args,
        logName,
        workingDirectory ? paths.hm,
        env ? { },
        flatLog ? false,
        runAtLoad ? true,
        keepAlive ? true,
        extra ? { },
      }:
      let
        base = logBase logName flatLog;
      in
      {
        Label = label;
        ProgramArguments = args;
        RunAtLoad = runAtLoad;
        KeepAlive = keepAlive;
        WorkingDirectory = workingDirectory;
        StandardOutPath = "${base}.out.log";
        StandardErrorPath = "${base}.err.log";
        EnvironmentVariables = {
          HOME = paths.home;
        }
        // env;
      }
      // extra;
  };
in
{
  inherit dlaunch;
}
