# home-manager/security.nix
{
  config,
  inputs,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    age # simple modern file encryption
    sops # encrypted secrets/config files
    gnupg # OpenPGP encryption and signing
  ];

  programs.gpg = {
    enable = true;
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = false;
  };

  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  home.sessionVariables.SOPS_AGE_KEY_FILE = config.sops.age.keyFile;

  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

    secrets = {
      FLAKEHUB_TOKEN = { };
      RAINDROP_TOKEN = { };
    };
  };

}
