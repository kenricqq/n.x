machine:

map (peer: {
  inherit (peer) name;

  id = peer.syncthing.devices.${peer.name}.id or null;
  tb = peer.network.tb or null;
  tailscale = peer.network.tailscale or null;
}) (machine.allowIncoming or [ ])
