{ pkgs, ... }:

let
  signalCliDaemon = pkgs.writeShellScript "signal-cli-daemon" ''
    signal_account="$(${pkgs.gnused}/bin/sed -n 's/^SIGNAL_ACCOUNT=//p' "$HOME/.hermes/.env")"
    if [[ ! "$signal_account" =~ ^\+[1-9][0-9]+$ ]]; then
      echo "signal-cli: invalid SIGNAL_ACCOUNT in ~/.hermes/.env" >&2
      exit 1
    fi

    exec ${pkgs.signal-cli}/bin/signal-cli \
      --account "$signal_account" daemon --http 127.0.0.1:8080
  '';
in
{
  # Replace the unit created by the imperative Hermes setup while keeping its
  # established service name. Hermes itself and ~/.hermes stay unmanaged.
  xdg.configFile = {
    "systemd/user/hermes-gateway.service".force = true;
    "systemd/user/default.target.wants/hermes-gateway.service".force = true;
  };

  systemd.user.services = {
    signal-cli = {
      Unit.Description = "Signal CLI HTTP daemon";

      Service = {
        ExecStart = signalCliDaemon;
        Restart = "on-failure";
        RestartSec = 3;
      };

      Install.WantedBy = [ "default.target" ];
    };

    hermes-gateway = {
      Unit = {
        Description = "Hermes Agent Gateway";
        Requires = [ "signal-cli.service" ];
        After = [ "signal-cli.service" ];
      };

      Service = {
        ExecStart = "%h/.local/bin/hermes gateway run";
        WorkingDirectory = "%h/.hermes";
        Restart = "always";
        RestartSec = 3;
      };

      Install.WantedBy = [ "default.target" ];
    };
  };
}
