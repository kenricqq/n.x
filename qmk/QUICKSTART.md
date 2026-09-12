# Corne v4.1 — session recap

## Recipes

Run from `/home/kenrict/meridian/qmk` (`just` is already installed here):

```sh
just                  # List recipes
just setup            # Recreate pinned QMK + relative keymap symlink
just build            # Build using the pinned temporary flake
just test             # Build, then run the 21 host tests
just shell            # Enter the flake shell in firmware/
just artifact         # Show the UF2 path and checksum
just devices          # Find RP2 Boot / RPI-RP2
just mount /dev/sdb1   # Use the actual partition from just devices
just flash            # Manually flash one mounted half; repeat for the other
```

Build/test/flash recipes enter the flake automatically. Build also runs setup. Bootmagic, TRRS and
USB-side instructions are below. `just flash` deploys the existing build;
run `just build` after changing the keymap. Device/mount recipes use the
machine's existing `lsusb`, `lsblk` and `udisksctl`.

The flake also includes `just`. On a machine with Nix but no `just`, first run
`nix develop path:/home/kenrict/meridian/qmk/env` from the `qmk` directory, then
use these recipes. Exit that shell to leave the temporary environment.

## Fresh clone / another machine

Fetch this folder including `keymaps/`, `scripts/`, `qmk-revision`, `env/` and
`justfile`. From the fetched `qmk/` directory:

```sh
nix develop "path:$PWD/env"
just test  # Setup, build, then test; never flash
```

Only `firmware/` is disposable/ignored. Custom sources belong in your repo at
`keymaps/miryoku_callum/`; setup creates a relative symlink into QMK.

## Setup recap

1. Created `env/flake.nix` + lock for temporary QMK/ARM tools; cloned QMK into
   `firmware/` at `08c662f286ddfd12a985f57b584b02eca5af0ae6`.
2. Initialized submodules: `chibios`, `chibios-contrib`, `pico-sdk`, `printf`,
   `lufa` (needed even for RP2040), and `googletest` under `lib/`.
3. Checked Corne hardware/APIs, current Callum half-layers, and Miryoku alphas.
   Created `firmware/keyboards/crkbd/keymaps/miryoku_callum/`: 34 active keys, held
   half-layer modifiers, shared bases, native NAV + RSYM → FN.
4. Built v4.0/v4.1 successfully; 10 host tests passed. Confirmed your PCB is
   **v4.1**, so use `crkbd/rev4_1/standard`; obsolete `crkbd/rev4` fails.
   Updated the Colemak base to **DHm** (M home, K bottom), Miryoku's default
   `COLEMAKDH`, following your later correction.

5. Added USB-left **Miryoku DHm (36 keys)** / USB-right **Callum Colemak-DHm (34 keys)**
   in the same `miryoku_callum` firmware. Start at **150 ms**, Quick Tap 0, Chordal Hold
   + Permissive Hold; Flow Tap / Auto Shift off. Restored Miryoku’s six thumbs.
   Current v4.1 build succeeds; **21 host tests pass**. No flashing performed.

## Re-enter, build, test

```sh
cd /home/kenrict/meridian/qmk
nix develop path:/home/kenrict/meridian/qmk/env
cd firmware
qmk compile -kb crkbd/rev4_1/standard -km miryoku_callum -j 4
make test:all TEST_LIST=keyboards/crkbd/keymaps/miryoku_callum/tests -j4
```

Compile v4.1 first to generate the layout header for tests. Ignore the old v4.0
artifact. Edit the source in `qmk/keymaps/miryoku_callum/`; timing is in its
`config.h`. The keymap path inside `firmware/` is a symlink to that folder.

## Flash each half manually — same v4.1 file twice

1. Unplug USB **before** disconnecting TRRS. Leave TRRS disconnected.
2. Hold the top-row key **second from the outside edge** while plugging USB
   directly into that half: left **Q**; right **apostrophe** in both current modes
   (P in the older QWERTY build). Release after two seconds. The right-side issue
   was holding the wrong key; the inaccessible BOOT button was unnecessary.
3. Detect and mount the bootloader, then flash from the shell above:

```sh
lsusb  # Expect 2e8a:0003 Raspberry Pi RP2 Boot
lsblk -o NAME,LABEL,FSTYPE,MOUNTPOINTS  # Find RPI-RP2
udisksctl mount -b /dev/sdb1  # Replace with the device shown NOW
python3 util/uf2conv.py --wait --deploy crkbd_rev4_1_standard_miryoku_callum.uf2
```

4. Wait for completion/reboot, unplug USB, then repeat on the other half.
5. With both halves unpowered, reconnect TRRS. USB-left selects Miryoku DHm;
   USB-right selects Callum Colemak-DHm **for both hands**. Fully unplug USB before changing
   sides; keep the host on US QWERTY. Bootmagic resets saved EEPROM settings.

Bootloader entry was confirmed; completed flashing/on-board behavior was not
independently verified. The agent never flashed hardware.

Full setup: [README.md](README.md). Layer diagrams:
[keymap reference](keymaps/miryoku_callum/readme.md).
