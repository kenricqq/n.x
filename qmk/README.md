# Corne v4.1 Miryoku / Callum setup and build guide

The QMK checkout is at `/home/kenrict/meridian/qmk/firmware`. The temporary
development environment is the separate flake in `env/`. Nothing was flashed.

Run `just` in this directory to list the recipes in [justfile](justfile).
`just setup` recreates the pinned checkout and keymap symlink. `just build`
runs setup then compiles, `just test` builds and runs the host suite, and
`just shell` enters the temporary environment. These commands use the pinned
flake automatically. `just devices`, `just mount DEVICE`, and `just flash`
support the manual flashing procedure; flashing is never a build/test dependency.
See [QUICKSTART.md](QUICKSTART.md) for recipe examples.

## Where the files came from

`firmware/` is a Git clone of `https://github.com/qmk/qmk_firmware.git`, pinned
to the revision below. It is QMK's complete source tree, supporting many
keyboards and microcontrollers. We did not write those thousands of files.
The temporary Nix environment provides build tools; it does not generate this
source tree or install all of those keyboards on your computer.

```text
qmk/
├── README.md                         Detailed setup and explanation
├── QUICKSTART.md                     Short build/flash guide
├── env/flake.nix + flake.lock         Temporary, pinned build tools
├── qmk-revision                      Pinned upstream QMK commit
├── scripts/setup.py                  Checkout and symlink bootstrap
├── keymaps/miryoku_callum/            Custom source: edit and commit this
└── firmware/                         Downloaded QMK Git checkout
    ├── keyboards/crkbd/              Upstream Corne hardware definitions
    │   └── keymaps/miryoku_callum     Relative symlink to our source above
    ├── quantum/                     QMK layers, tap/hold and key processing
    ├── platforms/ + drivers/         MCU, USB and peripheral support
    ├── lib/                         Downloaded supporting libraries
    ├── builddefs/ + util/            Build rules and helper tools
    ├── .git/                        Git metadata and submodule repositories
    ├── .build/                      Generated compiler output and host tests
    └── crkbd_rev4_1_standard_miryoku_callum.uf2   Flashable result
```

The sequence that produced this directory was:

1. Created `env/flake.nix` and its lock, then used `nix develop` to obtain QMK
   CLI, the ARM compiler, Make, Python and test tools. Nix keeps these packages
   in `/nix/store`; they are available in the temporary shell.
2. Cloned upstream QMK into `firmware/` and pinned its Git revision. This
   supplied the core engine, keyboard definitions, drivers, docs and utilities.
3. Initialized QMK's Git submodules: ChibiOS, ChibiOS-Contrib, Pico SDK, printf,
   LUFA and GoogleTest. The checkout also contains LVGL and V-USB submodules;
   QMK's build machinery can initialize missing submodules. Their presence
   does not enable display or AVR features in this Corne build.
4. Inspected Corne v4.1 hardware and QMK APIs, and read upstream Miryoku and
   Callum sources. Added our custom `keymaps/miryoku_callum/` folder. Miryoku's
   layer tables were adapted with attribution; upstream hardware files stayed
   unchanged. The previous keymap name was `callum34`.
5. Compiled the selected `crkbd/rev4_1/standard` target with that keymap. QMK
   generated intermediate files in `.build/` and the final `.uf2` in the
   checkout root. It does not compile every keyboard in the repository.
6. Ran our host tests using GoogleTest. These generate additional `.build/`
   files, but the tests themselves are not included in the flashable firmware.

Our main editable files are all in **`qmk/keymaps/miryoku_callum/`**, outside
the ignored checkout. QMK sees the same files through a relative symlink at
`firmware/keyboards/crkbd/keymaps/miryoku_callum`. There is no copied version
to synchronize. Edit either path and you edit the same source.

Files in the custom folder:

| File               | Purpose                                                          |
| ------------------ | ---------------------------------------------------------------- |
| `keymap.c`         | Callum keys, layer IDs, USB-side mode choice, Chordal Hold rules |
| `miryoku_layers.h` | Miryoku base and auxiliary layer tables                          |
| `config.h`         | 150 ms timing and mouse behavior                                 |
| `rules.mk`         | Enabled/disabled QMK features                                    |
| `readme.md`        | Complete layer diagrams and behavior reference                   |
| `tests/`           | Boot selection, mapping, timing and output-report checks         |

`keymap.c`, `config.h`, and `rules.mk` retain QMK's conventional filenames so
its build system finds them. The custom keymap folder and UF2 now use the
descriptive name `miryoku_callum`; the main test file is
`tests/test_miryoku_callum.cpp`. `QUICKSTART.md` replaces `README-quick.md`.

The compiler combines our files with the selected Corne hardware and QMK
runtime. The resulting UF2 contains the code/data needed by that build, not
the entire source checkout. To preserve your work, back up the custom keymap,
the flake files and these guides; upstream QMK can be cloned again at the pin.

## Enter the temporary environment

Nix with flakes is already installed on this machine. No Home Manager changes,
system package installation, Python virtual environment, or `qmk setup` is needed.

```sh
cd /home/kenrict/meridian/qmk
nix develop path:/home/kenrict/meridian/qmk/env
cd firmware
qmk --version
arm-none-eabi-gcc --version
```

`nix develop` opens a shell with QMK, its dependencies, the ARM compiler, Git,
Make, Python and a host C/C++ compiler for tests. The first invocation downloads
dependencies into `/nix/store`. `exit` leaves this shell and restores your normal
environment; store downloads remain eligible for normal Nix garbage collection.
It does not add these packages to your user profile. QMK's packaged dependencies
also include tools for other MCU families; their presence does not enable any
conversion flags in this firmware.

`env/flake.lock` pins nixpkgs to
`c5c4a43b0e8056328ec4529f735cabdb8f1942bb`, the same revision already pinned by
Meridian when this environment was created. This flake has its own lock and does
not change the main flake. It currently targets this machine's `x86_64-linux`.
The explicit `path:` URL makes newly created, untracked flake files visible to
Nix. Keeping the flake in `env/` prevents Nix from copying the firmware checkout
and build artifacts into the store as flake source.

## Recreate the checkout on another machine

Fetch or clone this `qmk/` folder with `keymaps/`, `scripts/`, `qmk-revision`,
`justfile`, and `env/` included. Commit those files to your source repository;
`firmware/` stays ignored and is intentionally absent from a fresh clone.
The scoped exceptions in `qmk/.gitignore` keep the custom keyboard source visible
under Meridian's broad parent ignore rule for names containing `key`.

From that fetched folder:

```sh
cd /path/to/qmk
nix develop "path:$PWD/env"
just setup
just test
```

The flake provides `just` and all build dependencies temporarily. If `just` is
already available, run `just setup` or `just test` directly; recipes enter the
flake themselves. Setup uses paths relative to this folder, so it works wherever
you put it. It:

1. Clones upstream QMK when `firmware/` is missing and checks out the commit in
   `qmk-revision` (currently `08c662f286ddfd12a985f57b584b02eca5af0ae6`).
2. Verifies that an existing checkout is already at the pin, without switching
   its revision or replacing existing keymap source.
3. Initializes the required pinned library submodules, including GoogleTest.
4. Creates the relative directory symlink to `keymaps/miryoku_callum/`.

Rerunning setup is safe. If a different checkout revision, real keymap directory,
or different symlink occupies the destination, setup stops with an explanation.
It never overwrites that source. Builds depend on setup, so a fresh machine can
also run `just build` directly. No setup/build/test recipe flashes hardware.

Verified: fresh bootstrap using cached real Git repositories, repeat setup,
relative link resolution, and preservation of a conflicting real directory.
The firmware build and all 21 host tests also pass through the symlink.

Keep the custom source and setup files in your repo; the upstream checkout,
its dependencies and `.build/` outputs can be reconstructed. No need to commit
QMK's entire source tree or generated UF2 files.

## Build for your confirmed Corne v4.1

The keymap is named `miryoku_callum` and contains two modes:

| USB connected to    | Whole-keyboard mode                           | Active keys |
| ------------------- | --------------------------------------------- | ----------: |
| Left physical half  | Miryoku Colemak-DHm, 150 ms tap/hold          |          36 |
| Right physical half | Callum Colemak-DHm, held half-layer modifiers |          34 |

Flash this same firmware to both halves. The left mode restores Miryoku's six
thumbs; Callum keeps the two outer thumbs disabled. Outer finger columns are
always disabled by the native `LAYOUT_split_3x5_3` macro.

From the firmware directory inside the flake shell:

```sh
qmk compile -kb crkbd/rev4_1/standard -km miryoku_callum -j 4
make test:all TEST_LIST=keyboards/crkbd/keymaps/miryoku_callum/tests -j4
```

Run the compile first: it generates the real v4.1 layout header used by the
host tests. No v4.0 build is needed. `crkbd/rev4` is obsolete in this checkout;
`mini` is not needed to disable the sixth columns on your standard PCB.

Artifact:

```text
/home/kenrict/meridian/qmk/firmware/crkbd_rev4_1_standard_miryoku_callum.uf2
```

Do not use the old v4.0 artifact left from earlier investigation. That build has
different split wiring and has not been updated with these Miryoku changes.
v4.1 uses GP12 serial, GP13 USB VBUS detection, and hardware GP21 handedness;
upstream hardware definitions are unchanged.

Verified 2026-09-14: QMK CLI 1.2.0, Arm GNU 15.2.Rel1 (GCC 15.2.1), successful
firmware build without warnings, **21 passing host tests**, valid RP2040 UF2.
Size: 81920 bytes. SHA-256:

```text
28d1dc1801ff66bf62420fa2094e555fda3c6ab7a7c3a2fdefd5cd85adb7e987
```

Tests exercise actual QMK key processing and USB reports with mocked USB role
and handedness. They check both whole-keyboard alpha mappings, EEPROM override
without persistence, Callum layers/modifiers/composition, Miryoku timing and
rolls, six thumb tap/hold functions, navigation/numbers/symbols/F-keys, mouse,
media and disabled positions. Every Miryoku table position was also checked
against upstream with documented adaptations. Callum’s auxiliary layers and
thumbs are unchanged; both bases now use DHm.
Physical split transport and typing feel still require on-board validation.

## Manual flashing — repeat on both halves

No hardware was flashed by the agent. Reflash **both halves** with the new file
so their firmware stays identical.

1. Unplug USB before disconnecting TRRS. Flash one half at a time with TRRS
   disconnected.
2. Hold the top-row key **second from that half's outside edge** while plugging
   USB directly into it. Left: Q position. Right: apostrophe in either current
   mode (P in the older QWERTY firmware). Release after two seconds. This Bootmagic method worked
   during the earlier session; no access to the PCB BOOT button is needed.
3. Detect the bootloader and mount its drive. Use the fresh device path shown
   by `lsblk`, not an assumed `/dev/sdb1`:

```sh
lsusb  # Expect 2e8a:0003 Raspberry Pi RP2 Boot
lsblk -o NAME,TRAN,LABEL,FSTYPE,SIZE,MOUNTPOINTS
udisksctl mount -b /dev/sdb1  # Replace with the current RPI-RP2 partition
```

4. From the firmware directory inside the temporary flake shell, run:

```sh
python3 util/uf2conv.py --wait --deploy crkbd_rev4_1_standard_miryoku_callum.uf2
```

5. Wait for completion/reboot, unplug USB, and repeat steps 2–4 on the other
   half with the **same file**. No split-left/right conversion or EEPROM
   handedness flags are needed. Bootmagic resets stored EEPROM settings.
6. With both halves unpowered, reconnect TRRS. Connect USB to the left half
   for Miryoku, or the right half for Callum. Keep the OS on US QWERTY.

If Bootmagic is unavailable in an older firmware, double-tapping RESET within
500 ms works when that firmware enables RP2040 double-tap reset; otherwise use
BOOT while plugging USB or BOOT + RESET. A mounted RPI-RP2 drive is required
for UF2 deployment. A file manager can mount it instead of `udisksctl`.

An alternative command that rebuilds and flashes when you explicitly run it:

```sh
qmk flash -kb crkbd/rev4_1/standard -km miryoku_callum
```

## Switch modes and tune timing

Release keys, unplug USB completely so both halves lose power, then reconnect
USB on the desired side. Use only one USB cable. QMK's USB master processes the
merged matrix from both halves, so its selected mode governs every key. Boot
selection overrides any old EEPROM default in RAM without saving a new value.

Miryoku starts with 150 ms, Quick Tap 0, Chordal Hold and Permissive Hold; Flow
Tap and Auto Shift are off. Edit
`keymaps/miryoku_callum/config.h` to tune the term, then
rebuild, test and manually reflash both halves. No installation changes needed.

See [the complete layer reference](keymaps/miryoku_callum/readme.md)
for diagrams, shortcut examples, timing tradeoffs and differences from upstream.
[QUICKSTART.md](QUICKSTART.md) is the concise session recap and flashing guide.
