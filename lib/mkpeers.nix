machine:

map (peer: {
  inherit (peer) name;

  id = peer.sync.id or null;
  tb = peer.sync.tb or null;
  tailscale = peer.sync.tailscale or null;
}) (machine.peers or [ ])
