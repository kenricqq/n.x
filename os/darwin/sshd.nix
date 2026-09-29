# allows other machines to SSH into Mac

{
  lib,
  machine,
  ...
}:

let
  allowIncoming = machine.allowIncoming or [ ];

  addresses = builtins.filter (address: address != null) (
    lib.concatMap (peer: [
      (peer.network.tb or null)
      (peer.network.tailscale or null)
    ]) allowIncoming
  );

  allowedUsers = lib.concatMapStringsSep " " (address: "${machine.user}@${address}") addresses;
in
{
  assertions = [
    {
      assertion = addresses != [ ];
      message = "sshd requires at least one configured peer address.";
    }
  ];

  services.openssh = {
    enable = true;

    extraConfig = ''
      AddressFamily inet
      PermitRootLogin no
      AuthenticationMethods publickey
      AllowUsers ${allowedUsers}
    '';
  };
}
