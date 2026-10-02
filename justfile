setup:
    lefthook install

# report missing, empty, or inaccessible service paths without changing them
check-paths:
    @uv run --no-project --offline --no-cache --no-python-downloads python scripts/check-paths.py

update_bun:
    bun update -g

# run Bun tests with Nix builds and import-from-derivation disabled
test *args:
    NIX_CONFIG="$(printf 'allow-import-from-derivation = false\nmax-jobs = 0\nbuilders = ')" bun test {{ args }}

# synchronize Home Manager NVIDIA userspace with pacman-installed nvidia-utils
nvidia-sync:
    bash scripts/nvidia-sync.sh

# install the notification-only pacman hook; requires sudo
install-nvidia-hook:
    command -v nvidia-sync
    sudo install -Dm644 scripts/95-nvidia-home-manager.hook /etc/pacman.d/hooks/95-nvidia-home-manager.hook
