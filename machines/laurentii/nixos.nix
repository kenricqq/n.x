{
  inputs,
  machine,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware.nix
    inputs.nix-index-database.nixosModules.default
  ];

  programs = {
    nh = {
      enable = true;
      clean.enable = true;
      flake = "/home/${machine.user}/${machine.repo or machine.name}#${machine.name}";
    };
    command-not-found.enable = false;
    niri.enable = true;
    waybar.enable = true;
    firefox.enable = true;
  };

  security.polkit.enable = true;
  security.rtkit.enable = true;

  services = {
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
    openssh.enable = true;
  };

  # disable cursor blinking
  boot.kernelParams = [ "vt.cur_default=0x700011" ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
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
    ];
    packages = [ pkgs.tree ];
  };

  nix.settings = (import ../../os/shared/nix-caches.nix) // {
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
