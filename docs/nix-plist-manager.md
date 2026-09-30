# Research: macOS settings with nix-plist-manager

Read official guides and source on 2026-09-30 at revision `f3ac4aaa9504e2f27da6314a47acea69a2e778e4`. Published docs were inaccessible through the web reader; their Markdown source was inspected instead. No Nix commands, builds, activation, or configuration changes were made.

## Setup and scope

Add `inputs.nix-plist-manager.url = "github:sushydev/nix-plist-manager";`. Import `inputs.nix-plist-manager.darwinModules.default` into nix-darwin and `inputs.nix-plist-manager.homeManagerModules.default` into Home Manager. Both use `programs.nix-plist-manager`, but expose different settings: HM manages user preferences; Darwin manages root-level firewall, sharing, power, updates, and login settings. Enable each scope separately. [Install guide][install], [flake exports][flake]

Example inside the Home Manager configuration:

```nix
programs.nix-plist-manager = {
  enable = true;
  options.applications.systemSettings = {
    appearance.appearance = "Dark";
    desktopAndDock.dock.size = 48;
  };
};
```

Option names and enum strings follow macOS controls. System settings use the same nesting in the Darwin module, e.g. `network.firewall.firewall = true;`. [Install guide][install]

## Behavior and caveats

- Omitted options, or `null`, remain unmanaged. Removing a declaration leaves its previously applied value; there is no automatic restoration of the pre-Nix state. Supported `"unset"` values delete stored preferences so macOS can fall back to defaults. **Documentation discrepancy:** the guide claims every option accepts `"unset"`; source disables it for several settings, including True Tone and firewall. [Guide][behavior], [option implementation][setting], [display settings][displays], [firewall settings][network]
- Activation writes settings, sends notifications, and restarts affected processes where specified. Some settings require logout. Some write failures are logged while activation continues; successful activation alone does not verify the resulting settings. [Guide][behavior], [renderer][render]
- Coexistence with `system.defaults` is possible: the Darwin module appends its script to the defaults activation stage. Recommendation: assign each preference one owner; there is no cross-module conflict detection in the inspected module. [Darwin module][darwin]

## Start from existing settings

Commands documented for execution **on the Mac**, not run here:

```sh
nix run github:sushydev/nix-plist-manager#current -- mac.nix --scope user
nix run github:sushydev/nix-plist-manager#current -- mac-system.nix --scope system
```

Import the corresponding file under `programs.nix-plist-manager.options`. Export omits known defaults; `--all` includes them, `--against mac.nix` reports differences, `--only` narrows scope, and `--verbose` reports unread settings. `--ui` opens System Settings; `--snapshots` captures layouts separately. Review exported values before adopting them. [Export guide][export]

Upstream reports 552 settings, 398 verified through the GUI, tested on **macOS 27 build 26A428**; earlier releases are untested. Export defaults use an exact or older recorded build, so they are not guaranteed to match another macOS version. Camera/microphone permissions, Screen Time, and account settings are outside coverage. [README][readme], [export implementation][current]

## Meridian fit

Recommended import locations: [`machines/m0nix/darwin.nix`](../machines/m0nix/darwin.nix) and [`machines/m0nix/home.nix`](../machines/m0nix/home.nix); `inputs` already reaches both through [`lib/mksystem.nix`](../lib/mksystem.nix). Existing [`os/darwin/system.nix`](../os/darwin/system.nix) manages shortcuts, Dock, Finder, and other defaults and is imported as a plain `system` attribute set. Keep module-level `programs.*` outside that file. Adopt selected settings first, removing overlapping declarations when migrated.

[install]: https://github.com/SushyDev/nix-plist-manager/blob/f3ac4aaa9504e2f27da6314a47acea69a2e778e4/docs/src/content/docs/guides/install.mdx
[flake]: https://github.com/SushyDev/nix-plist-manager/blob/f3ac4aaa9504e2f27da6314a47acea69a2e778e4/flake.nix
[behavior]: https://github.com/SushyDev/nix-plist-manager/blob/f3ac4aaa9504e2f27da6314a47acea69a2e778e4/docs/src/content/docs/guides/how-it-works.mdx
[setting]: https://github.com/SushyDev/nix-plist-manager/blob/f3ac4aaa9504e2f27da6314a47acea69a2e778e4/lib/settings/setting.nix
[displays]: https://github.com/SushyDev/nix-plist-manager/blob/f3ac4aaa9504e2f27da6314a47acea69a2e778e4/lib/options/applications/systemSettings/displays.nix
[network]: https://github.com/SushyDev/nix-plist-manager/blob/f3ac4aaa9504e2f27da6314a47acea69a2e778e4/lib/options/applications/systemSettings/network.nix
[render]: https://github.com/SushyDev/nix-plist-manager/blob/f3ac4aaa9504e2f27da6314a47acea69a2e778e4/lib/settings/render.nix
[darwin]: https://github.com/SushyDev/nix-plist-manager/blob/f3ac4aaa9504e2f27da6314a47acea69a2e778e4/modules/darwin/default.nix
[export]: https://github.com/SushyDev/nix-plist-manager/blob/f3ac4aaa9504e2f27da6314a47acea69a2e778e4/docs/src/content/docs/guides/from-your-mac.mdx
[readme]: https://github.com/SushyDev/nix-plist-manager/blob/f3ac4aaa9504e2f27da6314a47acea69a2e778e4/README.md
[current]: https://github.com/SushyDev/nix-plist-manager/blob/f3ac4aaa9504e2f27da6314a47acea69a2e778e4/tools/current.py
