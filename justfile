setup:
    lefthook install

# report missing, empty, or inaccessible service paths without changing them
check-paths:
    @uv run --no-project --offline --no-cache --no-python-downloads python scripts/check-paths.py

# export current Nix settings without building or activating
[private]
[macos]
_privacy-export:
    @nix eval --no-write-lock-file --option allow-import-from-derivation false \
        --option max-jobs 0 --option builders '' --raw \
        'path:{{justfile_directory()}}#darwinConfigurations.m0nix.config.environment.etc."nix-darwin/privacy-restrictions.mobileconfig".text' \
        > "${TMPDIR:-/tmp}/m0nix-privacy-restrictions.mobileconfig"
    @/usr/bin/plutil -lint "${TMPDIR:-/tmp}/m0nix-privacy-restrictions.mobileconfig"

# open current privacy profile; approve Install/Replace in Device Management
[macos]
privacy-setup: _privacy-export
    @/usr/bin/open "${TMPDIR:-/tmp}/m0nix-privacy-restrictions.mobileconfig"
    @/usr/bin/open 'x-apple.systempreferences:com.apple.Profiles-Settings.extension'
    @echo 'Approve Install/Replace in Device Management, then run just privacy-check.'

# compare effective, enforced macOS preferences with current Nix source
[macos]
privacy-check: _privacy-export
    @bun scripts/privacy-check.ts "${TMPDIR:-/tmp}/m0nix-privacy-restrictions.mobileconfig"

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
