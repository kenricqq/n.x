{ ... }:

{
  services.jellyfin = {
    enable = true;
    openFirewall = false;
    hardwareAcceleration = {
      enable = true;
      type = "qsv";
      device = "/dev/dri/renderD128";
    };
    forceEncodingConfig = true;
    transcoding = {
      enableHardwareEncoding = true;
      hardwareDecodingCodecs = {
        h264 = true;
        hevc = true;
        hevc10bit = true;
        mpeg2 = true;
        vp8 = true;
        vp9 = true;
        av1 = true;
      };
      hardwareEncodingCodecs = {
        hevc = true;
        av1 = true;
      };
    };
  };

  systemd.services.jellyfin.serviceConfig.SupplementaryGroups = [ "render" ];
  systemd.services.jellyfin.unitConfig.RequiresMountsFor = [ "/mnt/library/jellyfin" ];

  networking.firewall = {
    interfaces.tailscale0.allowedTCPPorts = [ 8096 ];
    # Keep the LAN exception scoped to Jellyfin's HTTP port.
    extraCommands = ''
      iptables -A nixos-fw -p tcp -s 10.0.0.185/32 --dport 8096 -j nixos-fw-accept
    '';
  };
}
