#!/usr/bin/env bash
set -u

focused_window_id="$(aerospace list-windows --focused --format '%{window-id}' 2>/dev/null || true)"

move_window() {
  local window_id="$1"
  local target_workspace="$2"

  [ -n "$target_workspace" ] || return 0
  aerospace move-node-to-workspace --window-id "$window_id" "$target_workspace" >/dev/null 2>&1 || true
}

target_workspace_for() {
  local app_id="$1"

  case "$app_id" in
    # Code
    com.todesktop.230313mzl4w4u92|dev.zed.Zed|com.microsoft.VSCode|com.apple.dt.Xcode)
      printf 'C'
      ;;

    # Terminal
    com.mitchellh.ghostty|com.raphaelamorim.rio|com.github.wez.wezterm|net.kovidgoyal.kitty)
      printf 'T'
      ;;

    # Browser / preview
    app.zen-browser.zen|org.mozilla.com.zen.browser|com.apple.Safari|net.imput.helium|com.apple.iphonesimulator)
      printf 'B'
      ;;

    # Assist
    com.openai.chat|com.anthropic.claudefordesktop)
      printf 'A'
      ;;

    # Design
    org.blenderfoundation.blender)
      printf 'D'
      ;;

    # Notes
    com.apple.Notes|md.obsidian|com.apple.iCal|com.apple.iBooksX|com.apple.Preview)
      printf 'N'
      ;;

    # Utilities
    com.apple.finder|com.apple.systempreferences|com.apple.systemsettings|com.docker.docker|com.electron.dockerdesktop|com.apple.findmy|com.apple.shortcuts|com.apple.FaceTime|org.whispersystems.signal-desktop|com.linear|app.yaak.desktop|com.blackmagic-design.DaVinciResolveLite|dev.kdrag0n.MacVirt)
      printf 'U'
      ;;
  esac
}

while IFS=$'\t' read -r window_id app_id _rest; do
  [ -n "$window_id" ] || continue
  target_workspace="$(target_workspace_for "$app_id")"
  move_window "$window_id" "$target_workspace"
done < <(aerospace list-windows --all --format "%{window-id}%{tab}%{app-bundle-id}%{tab}%{app-name}%{tab}%{window-title}%{tab}%{workspace}")

if [ -n "$focused_window_id" ]; then
  aerospace focus --window-id "$focused_window_id" >/dev/null 2>&1 || true
fi

if command -v sketchybar >/dev/null 2>&1; then
  sketchybar --trigger send_message MESSAGE="AeroSpace windows reset" >/dev/null 2>&1 || true
fi
