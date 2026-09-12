# Corne v4.1: Miryoku left USB / Callum right USB

The keymap and build name are `miryoku_callum`. Edit this source folder at
`qmk/keymaps/miryoku_callum/`; `just setup` symlinks it into the ignored QMK
checkout. There is no copy to keep in sync. Flash the **same v4.1 UF2 to both
halves**. USB-left selects Miryoku Colemak-DHm (36 keys); USB-right selects
Callum Colemak-DHm (34 keys), for the **whole keyboard**. Keep the host on US QWERTY.
Fully power-cycle when changing USB sides. The selected mode is never persisted.

## Timing recommendation

`config.h` is the one place to tune the baseline:

```c
#define TAPPING_TERM 150
#define QUICK_TAP_TERM 0
#define PERMISSIVE_HOLD
#define CHORDAL_HOLD
```

- 150 ms applies to Miryoku's home-row mods, AltGr mod-taps and layer-taps.
  It is a tap/hold threshold, not a fixed delay added to every keypress.
- Same-hand finger rolls before the threshold settle as letters. Opposite-hand
  chords may hold: complete the second key's tap while keeping the modifier
  down and Permissive Hold activates it early. Releasing the modifier first
  generally produces a typing roll. Holding past 150 ms activates the hold.
- Thumb and Button layer-taps are exempt from the same-hand restriction, so
  layers can work with either hand. Thumb positions also allow modifier chords
  from either hand.
- Quick Tap 0 lets tap-then-hold become a modifier/layer immediately on the
  second press. It removes tap-then-hold letter/Backspace autorepeat; for repeated
  Backspace, hold NAV and hold its plain right-middle Backspace key.
- Flow Tap is off initially. Auto Shift is also off: use Shift or the symbol
  layer. This avoids a second timing mechanism while tuning home-row mods.
- Callum uses no dual-role keys; these tap/hold rules do not affect its alphas.
- An isolated Miryoku mod-tap released after 20 ms emits its letter at release;
  it does not wait out 150 ms. Callum emits that letter at key-down. Both are
  covered by USB-report timing tests. Rollover can buffer events until the
  pending tap/hold decision settles. A two-second delay is not explained by
  this 150 ms threshold and would need separate diagnosis if observed.

Start here, then change one setting at a time based on actual misfires.
If letters accidentally become modifiers, try a longer term such as 180 ms. Same-hand shortcuts require waiting for the
term or using the opposite-hand modifier; that is the Chordal Hold tradeoff.

## Miryoku (USB-left)

These are the standard, unflipped Miryoku positions, with the optional features
listed below omitted. `OFF` means `KC_NO`. All six thumb positions are active.
Thumb order is left outer/middle/inner | right inner/middle/outer.

Base tapping output (DHm, **M home / K bottom**):

```text
Q     W     F     P     B      J     L     U     Y     '
A     R     S     T     G      M     N     E     I     O
Z     X     C     D     V      K     H     ,     .     /

           Esc Space Tab      Enter Bspc Delete
```

Base holding functions (`—` is an ordinary key with no dual role):

```text
—     —     —     —     —      —     —     —     —     —
GUI   Alt   Ctrl  Shift —      —     Shift Ctrl  Alt   GUI
Button AltGr —    —     —      —     —     —     AltGr Button

           Media Nav Mouse    Sym   Num   Fun
```

Miryoku uses left GUI/Alt/Ctrl/Shift keycodes on both hands, as upstream does;
AltGr is right Alt. Callum retains its original left/right modifier keycodes.

NAV — hold left middle Space:

```text
OFF   OFF   OFF   OFF   OFF    Redo  Paste Copy  Cut   Undo
GUI   Alt   Ctrl  Shift OFF    CapsW Left  Down  Up    Right
OFF   AltGr OFF   OFF   OFF    Ins   Home  PgDn  PgUp  End

           OFF   OFF   OFF    Enter Bspc  Delete
```

`CapsW` toggles Caps Word. For terminal Ctrl+U, hold base **S/Ctrl** and tap
base **U** on the opposite hand. NAV changes U's physical position to Copy;
NAV + Ctrl + that position is not Ctrl+U.

MOUSE — hold left inner Tab:

```text
OFF   OFF   OFF   OFF   OFF    Redo  Paste Copy  Cut   Undo
GUI   Alt   Ctrl  Shift OFF    OFF   Left  Down  Up    Right
OFF   AltGr OFF   OFF   OFF    OFF   WhLeft WhDown WhUp WhRight

           OFF   OFF   OFF    Btn2  Btn1  Btn3
```

MEDIA — hold left outer Escape:

```text
OFF   OFF   OFF   OFF   OFF    OFF   OFF   OFF   OFF   OFF
GUI   Alt   Ctrl  Shift OFF    OFF   Prev  Vol-  Vol+  Next
OFF   AltGr OFF   OFF   OFF    OFF   OFF   OFF   OFF   OFF

           OFF   OFF   OFF    Stop  Play  Mute
```

NUM — hold right middle Backspace:

```text
[     7     8     9     ]      OFF   OFF   OFF   OFF   OFF
;     4     5     6     =      OFF   Shift Ctrl  Alt   GUI
`     1     2     3     \      OFF   OFF   OFF   AltGr OFF

           .     0     -      OFF   OFF   OFF
```

SYM — hold right inner Enter:

```text
{     &     *     (     }      OFF   OFF   OFF   OFF   OFF
:     $     %     ^     +      OFF   Shift Ctrl  Alt   GUI
~     !     @     #     |      OFF   OFF   OFF   AltGr OFF

           (     )     _      OFF   OFF   OFF
```

FUN — hold right outer Delete (direct access, no Callum tri-layer chord):

```text
F12   F7    F8    F9    PrtSc  OFF   OFF   OFF   OFF   OFF
F11   F4    F5    F6    ScrLk  OFF   Shift Ctrl  Alt   GUI
F10   F1    F2    F3    Pause  OFF   OFF   OFF   AltGr OFF

           Menu  Space Tab    OFF   OFF   OFF
```

BUTTON — hold Z or slash:

```text
Undo  Cut   Copy  Paste Redo   Redo  Paste Copy  Cut   Undo
GUI   Alt   Ctrl  Shift OFF    OFF   Shift Ctrl  Alt   GUI
Undo  Cut   Copy  Paste Redo   Redo  Paste Copy  Cut   Undo

           Btn3  Btn1  Btn2   Btn2  Btn1  Btn3
```

Clipboard shortcuts: Undo Ctrl+Z, Redo Ctrl+Shift+Z, Cut Ctrl+X, Copy Ctrl+C,
Paste Ctrl+V. Application handling varies; terminals commonly require an extra
Shift for Copy/Paste. `Play` means Play/Pause; Btn1/2/3 mean left/right/middle.

## Callum (USB-right)

Callum now uses the same DHm alpha geometry as Miryoku. `TR` falls through
active lower layers to DHm. Its auxiliary layers and thumbs are unchanged. Both outer thumb keys remain OFF throughout this mode.

Colemak-DHm base (plain alphas):

```text
Q     W     F     P     B        J     L     U     Y     '
A     R     S     T     G        M     N     E     I     O
Z     X     C     D     V        K     H     ,     .     /

        OFF  LSYM  NAV           SPACE  RSYM  OFF
```

LSYM — hold the left middle thumb:

```text
1     2     3     4     5        TR    TR    TR    TR    TR
Ctrl  Alt   GUI   Shift Esc      TR    TR    TR    TR    TR
Caps  `     -     =     TR       TR    TR    TR    TR    TR

        OFF  TR    TR            TR    TR    OFF
```

RSYM — hold the right middle thumb:

```text
TR    TR    TR    TR    TR       6     7     8     9     0
TR    TR    TR    TR    TR       Esc   Shift GUI   Alt   Ctrl
TR    TR    TR    TR    TR       TR    [     ]     ;     \

        OFF  TR    TR            TR    TR    OFF
```

NAV — hold the left inner thumb:

```text
Alt+Tab Ctrl+W  Ctrl+PgUp Ctrl+PgDn Super+L   TR   Bspc  Up    Del   Tab
Ctrl    Alt     GUI       Shift     Esc       Esc  Left  Down  Right Enter
Alt+`   Ctrl+R  Alt+Left  Alt+Right OFF       TR   Vol-  Vol+  Play  TR

                    OFF  TR  TR             TR  TR  OFF
```

`Play` is Play/Pause. Shortcuts are obvious named macros at the top of `keymap.c`.
Alt+Tab is a normal chord each time, not a custom sticky app-switcher.

FN — hold NAV and RSYM together:

```text
F1    F2    F3    F4    F5       F6    F7    F8    F9    F10
Ctrl  Alt   GUI   Shift Esc      Esc   Shift GUI   Alt   Ctrl
F11   F12   OFF   OFF   OFF      OFF   OFF   OFF   OFF   OFF

        OFF  TR    TR            TR    TR    OFF
```

The thumb transparency in all non-base layers preserves the exact physical
arrangement `OFF / LSYM / NAV | SPACE / RSYM / OFF` in every combination.

RSYM + right Ctrl + C sends Ctrl+C; RSYM + right Shift + A sends Shift+A.
LSYM + RSYM exposes both symbol halves; use Shift on the opposite hand for
shifted numbers/symbols. NAV + RSYM activates FN using QMK's native tri-layer
keycodes. For terminal Ctrl+U, use LSYM + left Ctrl + base U, not NAV.
Linux `caps:escape` host configuration can make Callum's Caps key act as Escape.

All omitted outer finger columns and optional extension positions are disabled
on **every layer**, through native `LAYOUT_split_3x5_3`.

## Why one image controls both halves

Verified against QMK commit `08c662f286ddfd12a985f57b584b02eca5af0ae6`:

1. `quantum/keyboard.c:keyboard_init()` calls `split_pre_init()` before matrix
   initialization. `quantum/split_common/split_util.c` records USB master and
   physical handedness. Corne v4 supplies GP21 handedness in its hardware JSON.
2. `quantum_init()` loads any EEPROM default-layer state. The final
   `keyboard_post_init_user()` hook runs after that, so it can safely replace a
   stale default *in RAM*. `default_layer_set()` does not write EEPROM.
3. The hook checks `is_keyboard_master()`, then uses `is_keyboard_left()` to set
   exactly one default-layer bit. The non-master does not independently choose a
   base. There is no `isLeftHand`, `MASTER_LEFT`, `MASTER_RIGHT` or `EE_HANDS` override.
4. `quantum/matrix.c` chooses row offsets by physical handedness, independently
   of master status. `quantum/matrix_common.c:matrix_post_scan()` combines local
   and remote matrix rows on the master.
5. `quantum/keyboard.c:should_process_keypress()` normally permits only the
   master to translate those events. Therefore its one selected default governs
   both hands, without custom split transactions or layer synchronization.

Fully power-cycle the split when changing USB sides. Do not attach USB to both
halves at once. For the complete setup and manual flashing procedure, see
`/home/kenrict/meridian/qmk/README.md`.

## Sources and deliberate differences

- [Miryoku Babel](https://github.com/manna-harbour/miryoku_babel/blob/master/readme.org)
  and [its QMK layer tables](https://github.com/manna-harbour/miryoku_qmk/blob/miryoku/users/manna-harbour_miryoku/miryoku_babel/miryoku_layer_alternatives.h)
  were checked on 2026-09-14. `miryoku_layers.h` adapts those tables, retaining
  attribution and translating obsolete mouse keycodes to current `MS_*` APIs.
- [QMK tap/hold documentation](https://docs.qmk.fm/tap_hold) and this checkout's
  `quantum/action_tapping.c` were checked. Chordal Hold + Permissive Hold is our
  recommended tuning, not a claim about Miryoku's upstream default behavior.
- Miryoku now uses 36 keys, deliberately restoring its familiar six thumb taps.
  This supersedes the original 34-key restriction in Miryoku mode only.
- Auto Shift, tap-dance boot/base selectors, layer locks, alternate tap/extra
  bases and Shift+Caps-Word-to-Caps-Lock override are omitted. Bootmagic remains
  available, and USB placement selects the mode. This is an adaptation of
  Miryoku's core layout, not an unmodified build of its userspace.
- Linux clipboard chords replace upstream's generic clipboard codes. Lighting,
  wireless and output-selection entries are OFF. No OLED, RGB, encoders, VIA,
  Vial, combos, one-shot modifiers or Pro Micro conversion is enabled.
- [Callum's half-layer design](https://github.com/callum-oakley/keymap) remains
  adapted for Linux application shortcuts; its bootloader and lighting slots
  stay disabled. Callum’s alpha base now also uses DHm. Its auxiliary layers and thumb functions
  are unchanged.

## Build, tests and flashing

From `/home/kenrict/meridian/qmk/firmware`, inside the temporary flake shell:

```sh
qmk compile -kb crkbd/rev4_1/standard -km miryoku_callum -j 4
make test:all TEST_LIST=keyboards/crkbd/keymaps/miryoku_callum/tests -j4
```

The tests use the real v4.1 generated layout header, keymap, QMK tap/hold engine
and keyboard/mouse/consumer reports. Boot-side detection is mocked. They cover
both whole-keyboard alpha outputs, EEPROM nonpersistence, disabled positions,
Callum composition/navigation/FN, Miryoku 150ms behavior, rolls, early modifier
and layer chords, six thumbs, navigation/numbers/symbols/F-keys, mouse/media,
and release ordering. Source comparison checked all 288 Miryoku positions and
confirmed all 144 Callum auxiliary-layer positions unchanged and all 30 base
alpha taps identical between modes.

Result: firmware built without warnings; **21 host tests passed**. Hardware
transport, typing feel and application behavior still need your physical test.
No flashing was performed. See [the concise guide](../../QUICKSTART.md)
for manual bootmagic/mount/deploy steps; use the same new UF2 on both halves.

Files changed for the Miryoku/Callum update (relative to this directory unless
otherwise specified):

- Created `config.h`, `miryoku_layers.h`, `tests/test_miryoku.inc`.
- Modified `keymap.c`, `rules.mk`, `readme.md`, `tests/config.h`, `tests/test.mk`,
  `tests/test_miryoku_callum.cpp`.
- Updated Meridian's `qmk/README.md`, `qmk/QUICKSTART.md`, and `MISTAKES.md`.
- Regenerated `qmk/firmware/crkbd_rev4_1_standard_miryoku_callum.uf2` and QMK's
  ignored `.build` intermediates. The flake and upstream hardware files were
  unchanged in this update.
