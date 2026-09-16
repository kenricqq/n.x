#!/usr/bin/env bash
set -euo pipefail

repo=${1:-"$(dirname "${BASH_SOURCE[0]}")/.."}
cd "$repo"
metadata=machines/meridian/nvidia-driver.json
sync_marker=/var/lib/nvidia-home-manager-sync-required
version=$(pacman -Q nvidia-utils | awk '{sub(/-[^-]+$/, "", $2); print $2}')
current=$(jq -r '.version' "$metadata")
hash=$(jq -r '.sha256 // empty' "$metadata")
updated=false

if [[ $current != "$version" || -z $hash ]]; then
  printf 'NVIDIA Home Manager target: %s -> %s\n' "$current" "$version"
  arch=$(uname -m)
  hash=$(nix store prefetch-file --json \
    "https://download.nvidia.com/XFree86/Linux-${arch}/${version}/NVIDIA-Linux-${arch}-${version}.run" | jq -er '.hash')
  tmp=$(mktemp "${metadata}.tmp.XXXXXX")
  trap 'rm -f "$tmp"' EXIT
  jq -n --arg version "$version" --arg sha256 "$hash" \
    '{version:$version,sha256:$sha256}' > "$tmp"
  chmod --reference="$metadata" "$tmp"
  mv "$tmp" "$metadata"
  updated=true
else
  printf 'NVIDIA Home Manager configuration already targets %s\n' "$version"
fi

if [[ $updated == true || ! -e /run/opengl-driver/lib/libEGL_nvidia.so."$version" ]]; then
  home-profile switch
  sudo "$(command -v non-nixos-gpu-setup)"
fi

if [[ -e $sync_marker ]]; then
  sudo rm -f -- "$sync_marker"
fi

loaded=$(cat /sys/module/nvidia/version 2>/dev/null || true)
printf '\nLoaded: %s\nInstalled/Home Manager: %s\n' "${loaded:-unavailable}" "$version"
[[ $loaded == "$version" ]] || printf '\nREBOOT REQUIRED. Do not restart Niri before reboot.\n'
