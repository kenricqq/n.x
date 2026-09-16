setup:
    lefthook install

update_bun:
    bun update -g

linux:
    # → displayport
    ddcutil -d 1 setvcp xF4 x00D0 --i2c-source-addr=x50 --noverify

    # → hdmi 1
    ddcutil -d 1 setvcp xF4 x0090 --i2c-source-addr=x50 --noverify

    # → hdmi 2
    ddcutil -d 1 setvcp xF4 x0091 --i2c-source-addr=x50 --noverify

# synchronize Home Manager NVIDIA userspace with pacman-installed nvidia-utils
nvidia-sync:
    bash scripts/nvidia-sync.sh

# install the notification-only pacman hook; requires sudo
install-nvidia-hook:
    command -v nvidia-sync
    sudo install -Dm644 scripts/95-nvidia-home-manager.hook /etc/pacman.d/hooks/95-nvidia-home-manager.hook
