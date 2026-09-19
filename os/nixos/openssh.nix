{ ... }:

{
  services.openssh = {
    enable = true;
    settings.AuthenticationMethods = "publickey";
  };
}
