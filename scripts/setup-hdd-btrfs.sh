#!/usr/bin/env bash

# hdd wipe, reformat, remount

set -e

DISK=/dev/sda
DEVICE=/dev/sda1
LABEL=library
MOUNT=/mnt/library
OWNER="${USER}"
LINK="${HOME}/library"

# confirm
read -rp "wipe, reformat, and remount hdd? type Y to continue: " CONFIRM
[[ "${CONFIRM}" == "Y" ]] || exit 1

# unmount
sudo umount "${DEVICE}" 2>/dev/null || true

# partition and format
sudo parted "${DISK}" --script mklabel gpt
sudo parted "${DISK}" --script mkpart primary btrfs 0% 100%
sudo mkfs.btrfs -f -L "${LABEL}" "${DEVICE}"

# create mount point
sudo mkdir -p "${MOUNT}"

# get uuid
UUID=$(sudo blkid -s UUID -o value "${DEVICE}")

# configure automount
sudo cp /etc/fstab /etc/fstab.backup
sudo sed -i "\|[[:space:]]${MOUNT}[[:space:]]|d" /etc/fstab

echo "UUID=${UUID} ${MOUNT} btrfs defaults,noatime,compress=zstd,nofail 0 0" \
  | sudo tee -a /etc/fstab >/dev/null

# reload systemd
sudo systemctl daemon-reload

# mount and set ownership
sudo mount "${MOUNT}"
sudo chown "${OWNER}:${OWNER}" "${MOUNT}"

# symlink
ln -sfnT "${MOUNT}" "${LINK}"

# verify
findmnt "${MOUNT}"
lsblk -f "${DEVICE}"
