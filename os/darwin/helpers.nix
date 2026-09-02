{
  lib,
  machine,
  pkgs,
}:

let
  inherit (lib) concatMapStringsSep concatStringsSep;

  dpath = rec {
    home = "/Users/${machine.user}";
    repo = "${home}/${machine.name}";
    hm = "${repo}/hm";
    dot = "${hm}/dots";
    darwin = "${repo}/os/darwin";
  };

  dlaunch = rec {
    script = name: text: "${pkgs.writeShellScriptBin name text}/bin/${name}";

    bun = "${pkgs.bun}/bin/bun";
    bunPath = concatStringsSep ":" [
      "${pkgs.bun}/bin"
      "${dpath.home}/.cache/.bun/bin"
      "${dpath.home}/.bun/bin"
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
      BUN_INSTALL = "${dpath.home}/.cache/.bun";
      PATH = bunPath;
    };

    logDir = name: "${dpath.home}/Library/Logs/${name}";
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
        workingDirectory ? dpath.hm,
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
          HOME = dpath.home;
        }
        // env;
      }
      // extra;
  };
in
{
  inherit dpath dlaunch;
}
