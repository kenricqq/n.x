{ host, pkgs, ... }:

{
  services.ollama = {
    enable = true;
    package = if host.isDarwin then pkgs.ollama else pkgs.ollama-cuda;
  };
}
