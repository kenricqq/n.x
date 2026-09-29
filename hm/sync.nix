{
  lib,
  machine,
  pkgs,
  ...
}:

{
  services.syncthing = lib.mkIf (machine ? syncthing) {
    enable = true;

    settings = {
      devices = removeAttrs machine.syncthing.devices [ machine.name ]; # exclude self

      folders = lib.mapAttrs (
        _: folder:
        folder
        // {
          enable = builtins.elem machine.name folder.devices;
          devices = lib.remove machine.name folder.devices;
          versioning = {
            type = "trashcan";
            params.cleanoutDays = "30";
          };
        }
      ) machine.syncthing.folders;

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
