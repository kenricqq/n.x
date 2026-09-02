#!/bin/bash
set -e

lock="${TMPDIR:-/tmp}/aerospace-on-ws-change.lock"
mkdir "$lock" 2>/dev/null || exit 0
trap 'rmdir "$lock"' EXIT

AEROSPACE_BIN="/etc/profiles/per-user/${USER}/bin/aerospace"
SKETCHYBAR_BIN="/etc/profiles/per-user/${USER}/bin/sketchybar"

current_monitor=$($AEROSPACE_BIN list-monitors --focused | awk 'NR==1 {print $1}')
current_workspace="${AEROSPACE_FOCUSED_WORKSPACE:-$($AEROSPACE_BIN list-workspaces --focused)}"

$AEROSPACE_BIN list-windows --monitor "$current_monitor" \
  | awk '/Picture-in-Picture|Picture in Picture/ {print $1}' \
  | while IFS= read -r number; do
      [ -z "$number" ] && continue
      $AEROSPACE_BIN move-node-to-workspace --window-id "$number" "$current_workspace" < /dev/null
    done

$SKETCHYBAR_BIN --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$current_workspace"
$SKETCHYBAR_BIN --trigger space_windows_change FOCUSED_WORKSPACE="$current_workspace"
