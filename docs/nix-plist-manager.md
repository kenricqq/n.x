# macOS preferences with nix-plist-manager

Source and Darwin evaluation checked on 2026-10-12 against the
[locked revision `4ef635b`](https://github.com/SushyDev/nix-plist-manager/tree/4ef635b8b2f4c88929ea7d1a8a941acbab5de719).
The configuration is integrated; activation and behavior on the Mac remain
unverified. Evaluation succeeded with builds and import-from-derivation disabled.

## Configuration ownership

- [hm/macos/system-settings.nix](../hm/macos/system-settings.nix) imports the
  Home Manager module and declares the migrated user preferences: 22 settings
  and 11 shortcuts. Only [m0nix's home profile](../machines/m0nix/home.nix)
  imports it. Commented options are examples, not active preferences.
- [machines/m0nix/darwin.nix](../machines/m0nix/darwin.nix) imports and enables
  the system module. Its optional machine-wide settings are all commented out.
- [os/darwin/system.nix](../os/darwin/system.nix) retains preferences and raw
  shortcuts whose exact behavior is not covered by the migration. It returns a
  plain `system` attribute set; module-level `programs.*` belongs outside it.

Give each preference one owner. During a full Darwin activation, retained raw
shortcut entries are written before Home Manager merges the migrated entries.
Compare the combined result when changing either side.

## Settings intentionally retained in nix-darwin

Paths below are relative to `system`. The Nix source remains authoritative for
values and shortcut parameter arrays.

| Setting | Reason retained |
| --- | --- |
| `defaults.dock.expose-animation-duration = 0.1` | No matching option in the pinned source. |
| `defaults.dock.showhidden = true` | Preserves dimming hidden apps; no matching option. |
| `defaults.dock.persistent-apps = [ ]` | Upstream Dock snapshots also replace `persistent-others`. |
| `defaults.finder.FXPreferredViewStyle = "Nlsv"` | Preserves default list view; no matching option. |
| `defaults.finder.AppleShowAllExtensions = true` | Existing preference targets Finder; upstream writes `NSGlobalDomain`. |
| `defaults.NSGlobalDomain._HIHideMenuBar = true` | Upstream enum also changes fullscreen visibility and Control Center selection. |
| `defaults.NSGlobalDomain.NSWindowShouldDragOnGesture = true` | Command-Control window dragging has no matching option. |
| `keyboard.enableKeyMapping` and `keyboard.remapCapsLockToEscape` | Preserve the existing Caps Lock → Escape mapping. |

Backing implementations: [Dock][dock], [Finder][finder], [menu bar][menubar].

The following 27 entries remain in
`defaults.CustomUserPreferences."com.apple.symbolichotkeys".AppleSymbolicHotKeys`:

| IDs | Preserved behavior / reason retained |
| --- | --- |
| `15–20`, `22–24` | Disabled individually; grouped zoom controls also change other state. |
| `32`, `33` | Option-Shift-K / Option-Shift-J; the Mission Control selector does not accept these letter bindings. |
| `34`, `35` | Disabled companion entries with saved K/J bindings. |
| `36`, `37` | F11 with function flag and Shift counterpart; upstream Show Desktop also writes IDs `48`, `49`. |
| `79`, `81` | Disabled with saved Option-H / Option-L; upstream `false` omits saved parameters. |
| `80`, `82` | Option-Shift-H / Option-Shift-L; no matching individual rows. |
| `118–123` | Disabled with saved Option-1 through Option-6; preserve stored combinations. Desktop 7/8 migrated separately. |
| `160`, `164` | Enabled/disabled respectively, both with `[ 65535 65535 0 ]`; preserve explicit unassigned-key parameters. |

Backing implementations: [shortcut encoding][codecs], [keyboard options][keyboard],
[Mission Control selector][mission]. Compare domain, key, scope, complete values,
and additional writes before moving any retained setting.

## Activation and verification

Omitted options and `null` leave existing values unmanaged; removing a declaration
will not restore the previous state. `"unset"` is supported only by options that
allow it. [Option implementation][setting]

Activation can clear ByHost overrides, restart affected apps, and refresh
shortcuts. Successful activation alone does not prove every preference applied.
The pinned upstream was tested on macOS 27 build 26A428; earlier releases are
untested. [Upstream compatibility][readme], [activation renderer][render]

Before applying on the Mac, check its macOS version and capture relevant current
preferences and shortcuts, including host-specific overrides. After activation,
verify Dock, Finder, menu-bar behavior, Caps Lock mapping, and both migrated and
retained shortcuts. The original migration compared declared values; live Mac
behavior and preservation of unmanaged overrides still need verification.

For a source-only check from the intended checkout:

```sh
nix eval --no-write-lock-file --option allow-import-from-derivation false \
  --option max-jobs 0 --option builders '' \
  --raw "path:$PWD#darwinConfigurations.m0nix.system.drvPath"
```

Upstream's [export guide][export] documents `#current`, user/system scopes, and
`--against` comparisons. Use the revision in `flake.lock`; review exports before
importing them. Running the exporter can build dependencies and reads the Mac
where it runs.

[dock]: https://github.com/SushyDev/nix-plist-manager/blob/4ef635b8b2f4c88929ea7d1a8a941acbab5de719/lib/options/applications/systemSettings/desktop-and-dock/dock.nix
[finder]: https://github.com/SushyDev/nix-plist-manager/blob/4ef635b8b2f4c88929ea7d1a8a941acbab5de719/lib/options/applications/finder.nix
[menubar]: https://github.com/SushyDev/nix-plist-manager/blob/4ef635b8b2f4c88929ea7d1a8a941acbab5de719/lib/options/applications/systemSettings/menu-bar.nix
[codecs]: https://github.com/SushyDev/nix-plist-manager/blob/4ef635b8b2f4c88929ea7d1a8a941acbab5de719/lib/settings/codecs.nix
[keyboard]: https://github.com/SushyDev/nix-plist-manager/blob/4ef635b8b2f4c88929ea7d1a8a941acbab5de719/lib/options/applications/systemSettings/keyboard.nix
[mission]: https://github.com/SushyDev/nix-plist-manager/blob/4ef635b8b2f4c88929ea7d1a8a941acbab5de719/lib/options/applications/systemSettings/desktop-and-dock/mission-control.nix
[setting]: https://github.com/SushyDev/nix-plist-manager/blob/4ef635b8b2f4c88929ea7d1a8a941acbab5de719/lib/settings/setting.nix
[readme]: https://github.com/SushyDev/nix-plist-manager/blob/4ef635b8b2f4c88929ea7d1a8a941acbab5de719/README.md
[render]: https://github.com/SushyDev/nix-plist-manager/blob/4ef635b8b2f4c88929ea7d1a8a941acbab5de719/lib/settings/render.nix
[export]: https://github.com/SushyDev/nix-plist-manager/blob/4ef635b8b2f4c88929ea7d1a8a941acbab5de719/docs/src/content/docs/guides/from-your-mac.mdx
