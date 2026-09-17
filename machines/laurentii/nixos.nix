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

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];

    # Match the binary caches configured on Darwin; NixOS keeps its default cache.
    substituters = [
      "https://devenv.cachix.org"
      "https://helix.cachix.org"
      "https://fenix.cachix.org"
      "https://comfyui.cachix.org"
      "https://nix-community.cachix.org"
      "https://cache.nixos-cuda.org"
      "https://adithyagenie.cachix.org"
      "https://zig-overlay.cachix.org"
      "https://zigtools.cachix.org"
      "https://codex-desktop-linux.cachix.org"
      "https://jj.cachix.org"
      "https://oxalica.cachix.org"
    ];
    trusted-public-keys = [
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
      "fenix.cachix.org-1:ecJhr+RdYEdcVgUkjruiYhjbBloIEGov7bos90cZi0Q="
      "comfyui.cachix.org-1:33mf9VzoIjzVbp0zwj+fT51HG0y31ZTK3nzYZAX0rec="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      "adithyagenie.cachix.org-1:h6BSMboeVfxyrULWuRQqAyweo4AJRATekb88xotfQwc="
      "zig-overlay.cachix.org-1:MCS36+WBxE8vqfE4j5BnCAx0Gse9EnTLSukAvP8JwtA="
      "zigtools.cachix.org-1:USl8MDuq1Jyx4pET+Q8siEIf1Nfja7hyXr9NuOf12PU="
      "codex-desktop-linux.cachix.org-1:nX/xy6AdK9hQE24A8ALGjkCKj2ObFmcnemiL5Cid4nk="
      "jj.cachix.org-1:rOXYMWIM8CAjR0M3kifWXVoDXVriTPz+gX5oSdJe2Is="
      "oxalica.cachix.org-1:h0iRBw6tQD8+51ZvnNEBPbwLR58UD7klauDBWzBdugQ="
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
      ghostty
      jujutsu
      bun
      nodejs
      bubblewrap
      alacritty
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
