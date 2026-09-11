{
  lib,
  machine,
  paths,
  pkgs,
  ...
}:

let
  inherit (paths)
    home
    ;

  peers = builtins.filter (p: p ? sync) (machine.peers or [ ]);

  peerNames = map (p: p.name) peers;

  devices = builtins.listToAttrs (
    map (
      p:
      lib.nameValuePair p.name {
        id = p.sync.id;
        addresses = [
          "tcp://${p.sync.tailscale}:22000"
          "tcp://${p.sync.tb}:22000"
          "dynamic"
        ];
      }
    ) peers
  );

  mkFolder = id: path: {
    inherit id;
    path = "${home}/${path}";
    devices = peerNames;

    versioning = {
      type = "trashcan";
      params.cleanoutDays = "30";
    };
  };
in
{
  services.syncthing = lib.mkIf (machine ? sync) {
    enable = true;

    settings = {
      inherit devices;

      folders = {
        sync = mkFolder "sync" "Sync";
        # documents = mkFolder "documents" "Documents";
        # projects = mkFolder "projects" "Projects";
      };

      options.urAccepted = -1;
      gui.theme = "black";
    };
  };

  services.restic = {
    enable = true;
    backups = {
      #   localbackup = {
      #     exclude = [
      #       "/home/*/.cache"
      #     ];
      #     initialize = true;
      #     passwordFile = "/etc/nixos/secrets/restic-password";
      #     paths = [
      #       "/home"
      #     ];
      #     repository = "/mnt/backup-hdd";
      #   };
      #   remotebackup = {
      #     extraOptions = [
      #       "sftp.command='ssh backup@host -i /etc/nixos/secrets/backup-private-key -s sftp'"
      #     ];
      #     passwordFile = "/etc/nixos/secrets/restic-password";
      #     paths = [
      #       "/home"
      #     ];
      #     repository = "sftp:backup@host:/backups/home";
      #     timerConfig = {
      #       OnCalendar = "00:05";
      #       RandomizedDelaySec = "5h";
      #     };
      #   };
    };
  };

  home.packages = with pkgs; [
    localsend # open source airdrop

    rsync # backup & two-way sync

    # borg # Deduplicating archiver with compression and authenticated encryption.
    # The main goal of Borg is to provide an efficient and secure way to back up data. The data deduplication technique used makes Borg suitable for daily backups since only changes are stored. The authenticated encryption technique makes it suitable for backups to targets not fully trusted.

    # rlone # cloud storage sync files
  ];
}
