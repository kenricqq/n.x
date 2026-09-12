# QMK handoff

## Start here

- Follow the parent repository's `AGENTS.md`; read `../MISTAKES.md` before
  code/config changes when working inside Meridian.
- Ask questions directly in chat. The user cannot see follow-up input widgets.
- Use the temporary Nix flake in `env/` for tools. Give explicit steps for any
  new installation; keep it out of global packages/Home Manager unless requested.
- Build and validate only. **Do not flash hardware automatically.** The flash
  recipe is for the user to run manually on each half.

## Preserve these decisions

- Hardware is confirmed **wired Corne v4.1, RP2040**, standard six-column PCB.
  Target: `crkbd/rev4_1/standard`; keymap: `miryoku_callum`.
- Both controllers receive the same UF2. USB-left selects **Miryoku DHm, 36
  keys/all six thumbs**; USB-right selects **Callum DHm, 34 keys/four thumbs**.
  Both modes govern the whole keyboard. There is no QWERTY firmware base;
  the host stays on ordinary US QWERTY.
- DHm means **M on home, K on bottom**. Before alpha/layer changes, read the
  exact diagrams and upstream references in [the keymap reference](keymaps/miryoku_callum/readme.md).
  Earlier requests for DHk, Callum QWERTY and 200 ms were superseded.
- Miryoku uses **150 ms for finger and thumb dual-role keys**, Quick Tap 0,
  Chordal Hold + Permissive Hold. Flow Tap and Auto Shift are off. Callum has
  plain alphas and held half-layer modifiers, with NAV + RSYM activating FN.
- Timing sensitivity matters: a short mod-tap emits its letter on release,
  not after a mandatory 150 ms wait. Callum alphas emit on key-down. Avoid
  describing the tapping term as a fixed delay on every key.
- Use native `LAYOUT_split_3x5_3`; outer finger columns stay disabled. Miryoku
  deliberately restores the two outer thumb keys that Callum disables.
- Keep hardware configuration upstream. Use current `is_keyboard_master()` /
  `is_keyboard_left()` APIs and the post-init RAM-only default-layer choice;
  do not persist the automatic mode. Fully power-cycle when switching USB sides.
- Preserve the wired-only scope: no VIA/Vial, OLED, RGB, encoder behavior,
  combos, tap dance, one-shot substitutions or Pro Micro conversion flags.

## Source ownership and setup

- Edit **`keymaps/miryoku_callum/`**. The corresponding directory inside
  `firmware/keyboards/crkbd/keymaps/` is a **relative symlink**, not a copy.
- `firmware/` is an ignored upstream Git checkout, not our authored project.
  Keep the custom source, `justfile`, `scripts/setup.py`, `qmk-revision`, flake
  files and guides in the parent repo; do not vendor the full QMK tree.
- Run `just setup` from this directory to recreate the pinned checkout,
  library submodules and symlink. The pin is in `qmk-revision`. Setup refuses
  conflicting source or a different existing revision; investigate rather
  than forcing replacement. Builds run setup automatically.
- Preserve `.gitignore` exceptions for our keymap. Meridian's parent
  `**/*key*` rule otherwise hides `keymaps/` and `keymap.c`; check Git visibility
  after moving or adding source.
- For fresh-machine setup, source provenance or dependency details, read
  [README.md](README.md). For manual bootloader/mount/flash steps, read
  [QUICKSTART.md](QUICKSTART.md); Bootmagic works without reaching the BOOT button.

## Verify and hand back

- After firmware or build/setup changes, run `just test` here. It builds the
  v4.1 target first to generate the real Corne layout header, then runs our
  QMK host suite. Fix attributable compiler warnings/errors and test failures.
  Documentation-only changes need link/content checks, not a firmware rebuild.
- For bootstrap changes, also check repeat setup, relative link resolution,
  fresh reconstruction and preservation of conflicting existing source.
- Last verified on 2026-09-14: build without warnings, **21 host tests passed**;
  fresh setup tested with cached real Git repositories. Tests mock USB role
  and handedness, not QMK key processing. They do not prove physical split
  transport, host shortcut behavior or typing feel.
- `just artifact` prints the current UF2 path/hash. The expected filename is
  `firmware/crkbd_rev4_1_standard_miryoku_callum.uf2`; use that same file on
  both halves. Report validation and remaining hardware checks accurately.
- Update affected layer diagrams, setup instructions and recipe examples when
  behavior or paths change. Keep this file focused on decisions; put detailed
  explanations in the linked guides.
