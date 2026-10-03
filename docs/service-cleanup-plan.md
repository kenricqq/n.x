# Remaining service work

Updated 2026-10-03. Remaining fixes and deferred decisions only. Linux findings are from source; remote runtime has not been audited.

| Item | Remaining work | Location |
|---|---|---|
| PostgreSQL application login | Server works. When connecting an application, verify its database credentials. The passwordless TCP probe returned `no password supplied`; authenticated SQL remains untested. | [Darwin configuration](../machines/m0nix/darwin.nix) |
| Glance YouTube feeds | Investigate when failures recur. Earlier 404s affected Fireship, Jeff Geerling, 3Blue1Brown and Veritasium. Capture fresh errors before changing channel IDs; no current failure reproduced. | [Glance configuration](../dots/glance/glance.yml) |
| Memos tailnet access | Optional setup below. Last check: local HTTP 200, Tailscale `No serve config`. Authenticated use across devices remains untested. | [Launch agents](../os/darwin/launchd.nix) |
| Restic backups | Deferred. Choose destination, credentials, paths and retention; complete a backup and restore test before enabling a schedule. No backup jobs configured. | [Sync](../hm/sync.nix) |
| Linux clipboard watchers | Source deduplicated. After updating each Linux host and logging in again, verify one text watcher and one image watcher with `pgrep -af wl-paste`. | [Niri startup](../dots/niri/config.d/50-startup.kdl) |
| Linux Ollama | Meridian autostarts CUDA Ollama and retains its CLI. Laurentii has neither service nor CLI configured. After applying, verify `systemctl --user status ollama.service` on Meridian and absence of the unit and CLI on Laurentii. Remote runtime unverified. | [Ollama](../hm/dev/ollama.nix) |
| Laurentii cleanup schedule | Disabled in both NixOS and Home Manager source. After applying, verify no nh cleanup timer remains with `systemctl list-timers --all`. Runtime unverified. | [Laurentii configuration](../machines/laurentii/nixos.nix) |

Optional PostgreSQL logging reduction: change `log_statement = "all"` to `"none"` unless full SQL logging is intentional. Error logging is controlled separately. No battery savings measured. [PostgreSQL logging settings](https://www.postgresql.org/docs/18/runtime-config-logging.html).

**Memos tailnet access**

Keep one SQLite-backed Memos server and access it from every device through Tailscale. To expose the existing Mac server:

```sh
/Applications/Tailscale.app/Contents/MacOS/Tailscale serve --bg http://127.0.0.1:8082
/Applications/Tailscale.app/Contents/MacOS/Tailscale serve status
```

Complete the printed HTTPS enablement flow if prompted. Open the returned URL from two tailnet devices, sign into the same Memos account, then create on one and read/edit on the other. If denied, check access to this node's TCP 443. The route persists across Tailscale restarts; Mac sleep interrupts access. [Serve CLI](https://tailscale.com/docs/reference/tailscale-cli/serve).

| Hosting approach | Tradeoff |
|---|---|
| Current Mac, SQLite | Smallest change; unavailable while Mac sleeps. |
| Always-on tailnet host, SQLite | Better availability; migrate a consistent backup and attachments first. |
| PostgreSQL backend | Adds a database dependency; unnecessary for multiple devices sharing one server. |
| Separate servers with export/import | Manual transfer, not continuous or offline synchronization. |

Current data: `~/KTQQ/docs/notes/memos/`. Before migrating, back up SQLite consistently plus attachments and configuration, then test restoration. Do not synchronize live SQLite/WAL files between independent servers. [Memos backup and restore](https://usememos.com/docs/operations/backup-restore), [database choices](https://usememos.com/docs/configuration/database), [SQLite WAL](https://www.sqlite.org/wal.html).

**Deferred pruning decisions**

| Item | Next decision or check |
|---|---|
| Hermes and Signal CLI | Both enabled through the [shared Linux import](../hm/_linux-desktop.nix). Inspect runtime using commands below. If unused, remove the import of `./linux/hermes.nix`; if kept, verify Hermes installation and Signal account setup. [Service definitions](../hm/linux/hermes.nix) restart after relevant failures every 3 seconds. |
| Fcitx5, Handy and OpenRGB | Decide which Linux input/startup tools are still wanted. |
| iNiR and Super-key helper | Inspect installed Linux units before pruning; setup can also enable ydotool, Bluetooth and SDDM. |
| NVIDIA reminder | [Meridian timer](../machines/meridian/home.nix) checks for a pending update marker. Keep unless replacing that workflow. |
| Laurentii desktop services | Review GNOME and printing if unused. Preserve audio, networking, SSH and the active login/session setup. [Configuration](../machines/laurentii/nixos.nix). |
| ClamAV and OrbStack leftovers | Decide whether packages/helpers are still wanted. Earlier audit: ClamAV user plist unloaded; OrbStack helper idle. |
| Codex and skills updater module | [Module](../hm/misc/tool-updates.nix) not imported. Remove unused source or explicitly adopt; no current daemon savings. |
| Pi shim and Atlas source watcher | [Imports and declarations](../os/darwin/launchd.nix) commented out. Retain or remove based on workflow use. |
| Glances web monitor | [Unimported systemd module](../os/darwin/services/glances/default.nix) under Darwin. Remove or relocate if wanted. |
| Auto-cpufreq artifact | [Unused Linux package definition](../os/darwin/_mlx-lm.nix) under a misleading filename. Review/remove separately. |
| Memos and Golink hosting | Move to an always-on host only if access while Mac sleeps matters. |

On each Linux host, inspect Hermes and Signal without changing them:

```sh
systemctl --user status signal-cli.service hermes-gateway.service
journalctl --user -u signal-cli.service -u hermes-gateway.service -n 50 --no-pager
```
