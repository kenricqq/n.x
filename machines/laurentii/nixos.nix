{
  config,
  inputs,
  lib,
  machine,
  paths,
  pkgs,
  ...
}:

let
  memosHomeDir = "${paths.dataHome}/memos";
in
{
  imports = [
    ./hardware.nix
    ../../os/nixos/jellyfin.nix
    ../../os/nixos/tailscale.nix
    ../../os/nixos/openssh.nix
    inputs.nix-index-database.nixosModules.default
  ];

  fileSystems."/mnt/library" = {
    device = "/dev/disk/by-uuid/094166e7-3055-451d-a365-3a86e6c9a2a0";
    fsType = "btrfs";
    options = [
      "noatime"
      "compress=zstd"
      "nofail"
    ];
  };

  programs = {
    nh = {
      enable = true;
      clean.enable = false;
      flake = "${paths.nixrt}#${machine.name}";
    };
    command-not-found.enable = false;
    niri.enable = true;
    waybar.enable = true;
    firefox.enable = true;
  };

  security.polkit.enable = true;
  security.rtkit.enable = true;

  hardware.i2c.enable = true; # for monitor input switching

  # Core Ultra 5 250K Plus iGPU: VA-API, QSV, and OpenCL tone mapping.
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vpl-gpu-rt
      intel-compute-runtime
    ];
  };

  services = {
    memos = {
      enable = true;
      user = machine.user;
      group = config.users.users.${machine.user}.group;
      # Manage the real directory; Home Manager owns the home symlink.
      dataDir = "${paths.dots}/memos";
      openFirewall = false;
      settings = {
        MEMOS_ADDR = "127.0.0.1";
        MEMOS_PORT = "8082";
        MEMOS_DATA = memosHomeDir;
        MEMOS_DRIVER = "sqlite";
        MEMOS_DSN = "${memosHomeDir}/memos_dev.db";
        MEMOS_INSTANCE_URL = "https://${machine.network.tailscaleDnsName}:8443";
      };
    };

    udev = {
      packages = [ pkgs.openrgb ];
      extraRules = ''
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="26ce", ATTRS{idProduct}=="01a2", OWNER="${machine.user}"
      '';
    };
    desktopManager.gnome.enable = true;
    displayManager = {
      gdm.enable = false;
      defaultSession = "niri";
      ly = {
        enable = true;
        settings = {
          # avoid Ly initial misplaced cursor
          default_input = "password";
          load = false;
          save = false;
        };
      };
    };
    xserver.xkb = {
      layout = "us";
      variant = "";
      options = "caps:escape";
    };
    printing.enable = true;
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  systemd.services.memos = {
    requires = [ "home-manager-${machine.user}.service" ];
    after = [ "home-manager-${machine.user}.service" ];
    serviceConfig = {
      Restart = "on-failure";
      # The module's ReadWritePaths permits writes only to dataDir under home.
      ProtectHome = lib.mkForce "read-only";
    };
  };

  systemd.services.memos-serve = {
    description = "Expose Memos through Tailscale Serve";
    wantedBy = [ "multi-user.target" ];
    wants = [
      "memos.service"
      "tailscaled.service"
    ];
    after = [
      "memos.service"
      "tailscaled.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${lib.getExe config.services.tailscale.package} serve --bg --yes --https=8443 http://127.0.0.1:${config.services.memos.settings.MEMOS_PORT}";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # disable cursor blinking
  boot.kernelParams = [ "vt.cur_default=0x700011" ];

  boot.loader = {
    systemd-boot = {
      enable = true;
      memtest86.enable = true;
    };
    efi.canTouchEfiVariables = true;
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    interfaces.thunderbolt0.ipv4.addresses = [
      {
        address = machine.network.tb;
        prefixLength = 24;
      }
    ];
  };

  time.timeZone = "America/Los_Angeles";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  users.users.${machine.user} = {
    isNormalUser = true;
    description = "Kenric T";
    extraGroups = [
      "networkmanager"
      "wheel"
      "i2c"
    ];
    packages = [ pkgs.tree ];
  };

  nix.settings = (import ../nix-caches.nix) // {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  environment = {
    sessionVariables = {
      PATH = [ "/home/${machine.user}/.bun/bin" ];
      EDITOR = "hx";
    };
    systemPackages = with pkgs; [
      ddcutil
      helix
      yazi
      ripgrep
      zoxide
      nushell
      wget

      alacritty
      ghostty
      kitty

      jujutsu
      bun
      nodejs

      bubblewrap

      fuzzel
      swaylock
      swayidle

      lf
      btop
    ];
  };

  # Preserve the compatibility baseline of the existing installation.
  system.stateVersion = "26.05";
}
