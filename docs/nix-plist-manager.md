# macOS preferences with nix-plist-manager

Source and Darwin evaluation checked on 2026-10-14 against the
[locked revision `4ef635b`](https://github.com/SushyDev/nix-plist-manager/tree/4ef635b8b2f4c88929ea7d1a8a941acbab5de719).
All 19 configuration-profile settings were verified live as applied and enforced
on 2026-10-14. Other migrated preferences and shortcuts still need behavior checks.
Evaluation succeeded with builds and import-from-derivation disabled.

## Configuration ownership

- [hm/macos/system-settings.nix](../hm/macos/system-settings.nix) imports the
  Home Manager module and declares the managed user preferences and shortcuts.
  Only [m0nix's home profile](../machines/m0nix/home.nix)
  imports it. Commented options are examples, not active preferences.
- [machines/m0nix/darwin.nix](../machines/m0nix/darwin.nix) imports and enables
  the system module and disables Share Mac Analytics. Other optional machine-wide
  settings are all commented out.
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

`defaults.CustomUserPreferences` also disables Improve Siri and Dictation, Look Up
suggestions, and Safari suggestions. These preferences have no matching option in
the pinned nix-plist-manager source.

Game Center, Spotlight internet results, Apple Music, and the Book Store are
disabled in a configuration profile declared in
[machines/m0nix/darwin.nix](../machines/m0nix/darwin.nix), using Apple's
[restrictions payload](https://github.com/apple/device-management/blob/release/mdm/profiles/com.apple.applicationaccess.yaml).
Apple Music is disabled with `allowMusicService = false` (macOS 10.12+), which
returns Music to classic mode. `allowBookstore = false` removes the Book Store tab
(macOS 15+).

The same profile contains all **24 functional settings** from the supplied
RemoveMacAI AI profile, plus the four service restrictions above: **28 settings**
in total. RemoveMacAI is not needed to generate, apply, or check these settings.
The AI controls match
[RemoveMacAI's feature definitions](https://github.com/omlahore/RemoveMacAI/blob/e0d3faeef05f41896db9e0e6f92cd0ef9c2b3fa2/Sources/removemacai/Catalog.swift):

- Restrictions disable Siri, external AI integrations and sign-in, Writing Tools,
  Genmoji, Image Playground, Mail summaries and smart replies, Safari summaries,
  and Notes transcription summaries.
- [Managed preferences payloads](https://github.com/apple/device-management/blob/release/mdm/profiles/com.apple.ManagedClient.preferences.yaml)
  disable automatic Mail summaries and smart replies, notification summaries,
  Messages summaries, inline text predictions, and Spatial Photos. They also
  enforce Siri's assistant, menu visibility, and voice-trigger settings off.
- Five MobileAsset URL overrides block downloads for foundation models,
  image/Genmoji models, Xcode completion, Photos Clean Up, and Spatial Photos.
  The loopback URL matches RemoveMacAI's profile; its path does not require the
  app or a running server. These are private asset-service preferences.

RemoveMacAI's four bookkeeping values (`installed`, `ai`, `kept`, `tweaks`) are
not Apple feature controls and are omitted. No downloaded models are deleted.

Each managed-preferences payload contains exactly one preference domain, with its
own stable identifier and UUID. On macOS 27.0.1, bundling all five domains in one
payload installed successfully but left five preferences unapplied; ManagedClient
logged `expected 1 managed prefs dict, but found 5`. Verify both installation and
effective forced values after replacing the profile.

Apple marks these AI restriction keys deprecated since macOS 26.4 in favor of
declarative device management. They remain in Apple's schema and RemoveMacAI's
macOS 27 profile; this configuration uses the manually installable profile form.
RemoveMacAI's status checks the restrictions and preferences above, so the existing
ChatGPT user toggle alone does not make its AI extensions row show off.

From the repo, install or update the profile with:

```sh
just privacy-setup
# Approve Install/Replace in System Settings → General → Device Management.
just privacy-check
```

Both recipes evaluate current Nix source with builds and import-from-derivation
disabled, exporting `m0nix-privacy-restrictions.mobileconfig` into `$TMPDIR` (or
`/tmp`). They do not activate Darwin or depend on a potentially stale `/etc` copy.
`privacy-setup` opens the exported profile and Device Management using
`/usr/bin/open`, so it also works from Nushell. macOS still requires manual approval
for each installation or update. Keep identifiers and UUIDs stable so updates
replace the existing profile.

To migrate from RemoveMacAI, install/replace **m0nix Privacy Restrictions** first,
then remove only the **RemoveMacAI** profile in Device Management and rerun
`just privacy-check`. It should report **28/28** after removal. The app can then
be removed normally; do not use its restoration workflow to undo the settings.
Evaluation exports the profile; activation places a copy in `/etc/nix-darwin`;
neither installs it. Install again when changing profile contents or setting up
a new Mac. An unchanged, installed profile persists across builds and restarts.

`privacy-check` derives expected settings from that export, including newly added
keys. It reads effective values with `CFPreferencesCopyAppValue` and requires
`CFPreferencesAppValueIsForced` for every key. Each line shows expected value,
actual value, and enforcement. Checker exit codes: `0` all applied, `1` missing, different,
or unenforced settings, `2` invalid profile or read error. This checks profile
settings; ordinary nix-plist-manager and `system.defaults` preferences are separate.
The check measures effective enforcement, not which profile supplied it. While
RemoveMacAI's profile remains installed, it can supply overlapping values; the
post-removal check verifies the completed migration.

Darwin activation also maps the profile and checker into `/etc/nix-darwin`, but
does not install the profile. To check against that deployed copy instead:

```sh
bun /etc/nix-darwin/privacy-check.ts
```

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
