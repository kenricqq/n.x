{
  pkgs,
  lib,
  host,
  machine,
  ...
}:

let
  peers = builtins.filter (peer: peer ? sync) (machine.peers or [ ]);

  tb = machine.sync.tb or null;

  allowedUsers = lib.concatMapStringsSep " " (ip: "${machine.user}@${ip}") (
    builtins.filter (ip: ip != null) (
      lib.concatMap (peer: [
        (peer.sync.tb or null)
        (peer.sync.tailscale or null)
      ]) peers
    )
  );

  tb-setup = pkgs.writeShellApplication {
    name = "tb-setup";

    text =
      if host.isDarwin then
        ''
          # note: sshd manages incoming ssh connection to mac

          # optional since darwin.nix should alr activate it
          sudo networksetup -setmanual \
            "Thunderbolt Bridge" \
            ${tb} \
            255.255.255.0 \
            0.0.0.0
        ''
      else if host.isLinux then
        ''
          sudo nmcli connection delete thunderbolt 2>/dev/null || true

          sudo nmcli connection add \
            type ethernet \
            ifname thunderbolt0 \
            con-name thunderbolt \
            ipv4.method manual \
            ipv4.addresses ${tb}/24 \
            ipv4.never-default yes

          ## restrict ssh to peers & require keys
          sudo install -d -m 0755 /etc/ssh/sshd_config.d
          sudo tee /etc/ssh/sshd_config.d/00-thunderbolt-key-only.conf >/dev/null <<'EOF'

          AllowUsers ${allowedUsers}
          AuthenticationMethods publickey

          ## BUT tailscale exceptions...
          # AllowUsers ${allowedUsers} ${machine.user}@100.64.0.0/10
          # Match LocalAddress *,!100.64.0.0/10
          #   AuthenticationMethods publickey
          # Match all
          EOF

          # Generate missing host keys on a fresh machine, then validate SSH.
          sudo /usr/bin/ssh-keygen -A
          sudo /usr/bin/sshd -t

          sudo ufw default deny incoming
          sudo ufw default allow outgoing

          # firewall rule (tb only; tailscaled manages tailscale0)
          ${lib.concatMapStringsSep "\n" (peer: ''
            sudo ufw allow \
              in on thunderbolt0 \
              from ${peer.sync.tb} \
              to ${tb} \
              port 22 \
              proto tcp
          '') peers}

          # enable only after adding allow rules; persist services across reboots
          sudo ufw enable
          sudo systemctl enable --now ufw sshd
          sudo systemctl reload sshd

          # apply security policy even if Thunderbolt cable disconnected
          sudo nmcli connection up thunderbolt
        ''
      else
        throw "tb-setup: unsupported operating system";
  };

  tb-reset = pkgs.writeShellApplication {
    name = "tb-reset";

    text =
      if host.isDarwin then
        ''
          exec ${lib.getExe tb-setup}
        ''
      else if host.isLinux then
        ''
          # resets ALL custom UFW rules, not just SSH rules; run locally
          if [[ -n "''${SSH_CONNECTION:-}" || -n "''${SSH_CLIENT:-}" ]]; then
            echo "tb-reset: run from a local terminal, not over SSH. Lockout risk." >&2
            exit 1
          fi

          # check prereqs before changing network/firewall.
          for cmd in sudo systemctl nmcli ufw tailscale /usr/bin/sshd /usr/bin/ssh-keygen; do
            if ! command -v "$cmd" >/dev/null; then
              echo "tb-reset: missing $cmd; install NetworkManager, OpenSSH, UFW and Tailscale first." >&2
              exit 1
            fi
          done

          read -r -p "Erase ALL custom UFW rules and recreate Thunderbolt? [y/N] " answer
          if [[ "$answer" != [yY] ]]; then
            exit 0
          fi

          sudo systemctl enable --now NetworkManager tailscaled

          # sign in if needed, preserving Tailscale preferences
          sudo tailscale up
          # Let tailscaled manage its firewall rules; use OpenSSH for tailnet SSH.
          sudo tailscale set --netfilter-mode=on --ssh=false --shields-up=false

          sudo ufw --force reset
          # A failed setup must not leave the firewall disabled.
          sudo ufw default deny incoming
          sudo ufw default allow outgoing
          sudo ufw --force enable
          sudo systemctl enable --now ufw

          # recreate only named TB connection/SSH policy/current peer rules
          ${lib.getExe tb-setup}

          sudo ufw status verbose
          tailscale status
          nmcli connection show
        ''
      else
        throw "tb-reset: unsupported operating system";
  };
in
{
  home.packages = lib.optionals (tb != null && !host.isNixos) [
    tb-setup
    tb-reset
  ];
}
