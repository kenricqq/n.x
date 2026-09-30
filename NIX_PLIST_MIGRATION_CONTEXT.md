# Nix-plist Migration: Retained macOS Settings

Context for the next agent investigating settings intentionally left in nix-darwin. Recorded 2026-09-30 in workspace `/home/kenrict/meridian/.ws/nix-plist`, jj change `nrst`.

## Current state

The migration moved 22 preferences and 11 shortcuts to [hm/macos/system-settings.nix](hm/macos/system-settings.nix), preserving their declared values. Another 27 user options and 9 system options are commented examples. User settings are imported only by `m0nix`; the Darwin module has no active new machine-wide settings.

Remaining settings below live in [os/darwin/system.nix](os/darwin/system.nix). That file returns a plain `system` attribute set, merged by [machines/m0nix/darwin.nix](machines/m0nix/darwin.nix). Module-level `programs.*` belongs outside it. These exclusions preserve behavior; a similarly named upstream option is insufficient evidence to migrate them.

Upstream is pinned to `f3ac4aaa9504e2f27da6314a47acea69a2e778e4`. [Research notes](docs/nix-plist-manager.md) contain installation details, source links, and compatibility limits.

## Retained preferences

Paths in this table are relative to `system`.

| Setting | Preserved value | Reason retained |
| --- | --- | --- |
| `defaults.dock.expose-animation-duration` | `0.1` | No matching option found in pinned upstream. |
| `defaults.dock.showhidden` | `true` | No matching option found; preserves dimming of hidden applications. |
| `defaults.dock.persistent-apps` | `[ ]` | Upstream `dock.contents` snapshot also replaces `persistent-others`; current declaration only clears pinned apps. |
| `defaults.finder.FXPreferredViewStyle` | `"Nlsv"` | Preserves default list view; no matching upstream option found. |
| `defaults.finder.AppleShowAllExtensions` | `true` | Current writer targets `com.apple.finder`; upstream `showAllFilenameExtensions` targets `NSGlobalDomain`. A migration would change preference scope. |
| `defaults.NSGlobalDomain._HIHideMenuBar` | `true` | Upstream menu-bar enum also writes fullscreen visibility and Control Center selection. Existing config declares only this flag. |
| `defaults.NSGlobalDomain.NSWindowShouldDragOnGesture` | `true` | Preserves Command-Control window dragging; no matching upstream option found. |
| `keyboard.enableKeyMapping`, `keyboard.remapCapsLockToEscape` | Both `true` | Existing nix-darwin Caps Lock → Escape mapping has no matching upstream option found. |

Authored comments remain, including the inactive `_HIHideMenuBar = false` alternative and hot-corner examples: top-left `10`, top-right `12`, bottom-left `5`, bottom-right `14`. They are examples, not active preferences.

## Retained shortcut entries

All 27 entries remain under `defaults.CustomUserPreferences."com.apple.symbolichotkeys".AppleSymbolicHotKeys`. The Nix file is authoritative for exact parameter arrays; preserve those arrays as well as `enabled`.

| IDs | Preserved state | Reason retained |
| --- | --- | --- |
| `15–20`, `22–24` | Disabled | No exact individual mapping established. Upstream grouped zoom control also touches additional state/IDs. |
| `32`, `33` | Enabled: Option-Shift-K / Option-Shift-J | Upstream Mission Control selector accepts function keys/arrows and modifier choices, not these letter bindings. |
| `34`, `35` | Disabled, with saved K/J parameter arrays | Keep disabled companion entries and their saved bindings intact. |
| `36`, `37` | Enabled: F11 with function flag, and Shift counterpart | Upstream Show Desktop selector additionally writes modifier entries `48` and `49`, previously undeclared. |
| `79`, `81` | Disabled, with saved Option-H / Option-L | Upstream boolean shortcut encoding writes only `enabled`, losing the stored binding. |
| `80`, `82` | Enabled: Option-Shift-H / Option-Shift-L | No matching individual rows exposed by pinned keyboard module. |
| `118–123` | Disabled, with saved Option-1 through Option-6 | Upstream `false` would discard the saved custom combinations. Desktop 7/8 were migrated separately. |
| `160`, `164` | Enabled / disabled respectively; both carry `[ 65535 65535 0 ]` | Preserve explicit unassigned-key parameters. Upstream boolean encoding drops them; no matching row found for `164`. |

Relevant upstream implementations: [shortcut encoding](https://github.com/SushyDev/nix-plist-manager/blob/f3ac4aaa9504e2f27da6314a47acea69a2e778e4/lib/settings/codecs.nix), [keyboard options](https://github.com/SushyDev/nix-plist-manager/blob/f3ac4aaa9504e2f27da6314a47acea69a2e778e4/lib/options/applications/systemSettings/keyboard.nix), [Mission Control selector](https://github.com/SushyDev/nix-plist-manager/blob/f3ac4aaa9504e2f27da6314a47acea69a2e778e4/lib/options/applications/systemSettings/desktop-and-dock/mission-control.nix).

During a full Darwin activation, retained raw shortcut entries are written before Home Manager merges migrated entries. Compare the combined result when changing either side.

## Verification and continuation

Setup checks passed: full Darwin derivation evaluation with import-from-derivation disabled; comparison of all original preference values and shortcut entries; validation of all 36 commented examples; formatting; absence of the module on Linux. No build or activation ran, and live Mac behavior is untested.

Those checks preceded subsequent parent Syncthing/network edits. The stale workspace was refreshed with `jj workspace update-stale` before writing this handoff; inherited edits were preserved. Re-evaluate the current revision before claiming it is validated.

1. Read [AGENTS.md](AGENTS.md) and [MISTAKES.md). Build/compilation and activation still require explicit user approval.
2. For any further migration, compare backing domain, key, scope, complete shortcut values, and extra writes against the pinned source. Keep retained declarations until equivalent behavior is established; remove duplicate declarations when migrating.
3. Evaluate from this workspace with an explicit `path:` reference. Bare `.` previously resolved to the enclosing main Git checkout:

   ```sh
   nix eval --no-write-lock-file --option allow-import-from-derivation false \
     --raw "path:$PWD#darwinConfigurations.m0nix.system.drvPath"
   ```

4. Before applying on the Mac, establish its macOS version. Upstream tests target macOS 27; earlier versions are untested. Activation also clears ByHost overrides for managed preferences (23 distinct keys in the evaluated migration), restarts affected apps, and refreshes shortcuts. Declared-value equality does not prove preservation of unmanaged host-specific overrides.

Temporary comparison tools were under `/tmp/nix-plist-*`; they are session artifacts, not tracked regression tests. Reconstruct checks from source if they are gone.
