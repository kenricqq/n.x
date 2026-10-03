# home-manager/security.nix
{
  config,
  inputs,
  paths,
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
    enable = false;
    enableSshSupport = false;
  };

  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  home.sessionVariables.SOPS_AGE_KEY_FILE = config.sops.age.keyFile;

  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    # Runtime string path: never copy the private identity into the Nix store.
    age.keyFile = "${paths.nixrt}/secrets/keys.txt";

    secrets = {
      FLAKEHUB_TOKEN = { };
      TS_AUTHKEY = { };

      # don't really use raindrop anymore...
      RAINDROP_TOKEN = { };
    };
  };

}
