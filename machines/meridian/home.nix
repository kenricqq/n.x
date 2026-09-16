{
  inputs,
  lib,
  machine,
  paths,
  pkgs,
  ...
}:

let
  nvidia = builtins.fromJSON (builtins.readFile ./nvidia-driver.json);
  syncMarker = "/var/lib/nvidia-home-manager-sync-required";
  nvidiaSync = pkgs.writeShellApplication {
    name = "nvidia-sync";
    runtimeInputs = with pkgs; [
      gawk
      jq
      nix
    ];
    text = ''
      exec ${lib.getExe pkgs.bash} ${lib.escapeShellArg (toString ../../scripts/nvidia-sync.sh)} ${lib.escapeShellArg paths.nixrt}
    '';
  };
in
{
  imports = [
  ]
  ++ (map (profile: ../../hm + "/${profile}") [
    "paths.nix"
    "_base.nix"
    "_dev.nix"
    "_linux-desktop.nix"
    "nixcord.nix"
  ]);

  home = {
    username = machine.user;
    homeDirectory = "/home/${machine.user}";
    stateVersion = "26.11";

    packages = [
      inputs.blender-cuda.packages.${machine.system}.blender-with-cuda-unstable
      nvidiaSync
    ];
  };

  programs.home-manager.enable = true;

  nixpkgs.config = {
    # cudaSupport = true;
    nvidia.acceptLicense = true;
  };

  targets.genericLinux = {
    enable = true;
    gpu = {
      enable = true;
      nvidia = {
        enable = true;
        inherit (nvidia) version sha256;
      };
    };
  };

  systemd.user = {
    services.nvidia-home-manager-reminder = {
      Unit = {
        Description = "Remind about pending NVIDIA Home Manager synchronization";
        ConditionPathExists = syncMarker;
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.libnotify}/bin/notify-send --urgency=critical --expire-time=0 'NVIDIA driver update requires synchronization' 'Run nvidia-sync, then reboot before restarting Niri.'";
      };
    };

    timers.nvidia-home-manager-reminder = {
      Unit.Description = "Periodically check for pending NVIDIA Home Manager synchronization";
      Timer = {
        OnBootSec = "1m";
        OnCalendar = "*:0/30";
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };

  xdg.enable = true;
}
