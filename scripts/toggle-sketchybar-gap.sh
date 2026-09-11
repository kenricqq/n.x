#!/usr/bin/env bash
set -euo pipefail

AEROSPACE_CONFIG="${AEROSPACE_CONFIG:-$HOME/.config/aerospace/aerospace.toml}"
VISIBLE_GAP=30
HIDDEN_GAP=0
MODE="${1:-toggle}"

get_current_gap() {
  python3 - "$AEROSPACE_CONFIG" <<'PY'
import sys
from pathlib import Path

for line in Path(sys.argv[1]).read_text().splitlines():
    stripped = line.strip()
    if stripped.startswith("outer.top"):
        _, rhs = stripped.split("=", 1)
        print(rhs.strip())
        break
else:
    sys.exit("Could not find outer.top in config")
PY
}

set_gap() {
  local value="$1"
  python3 - "$AEROSPACE_CONFIG" "$value" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
value = sys.argv[2]

lines = path.read_text().splitlines()
found = False

for i, line in enumerate(lines):
    if line.strip().startswith("outer.top"):
        indent = line[: len(line) - len(line.lstrip())]
        lines[i] = f"{indent}outer.top = {value}"
        found = True
        break

if not found:
    sys.exit("Could not find outer.top in config")

path.write_text("\n".join(lines) + "\n")
PY
}

get_hidden_state_from_gap() {
  local current_gap
  current_gap="$(get_current_gap)"

  if [[ "$current_gap" == "$HIDDEN_GAP" ]]; then
    echo on
  else
    echo off
  fi
}

get_hidden_state() {
  get_hidden_state_from_gap
}

show_bar() {
  # Update the gap first so a concurrent AeroSpace reload + --sync sees the
  # new desired state and doesn't invert the bar/gap pairing.
  set_gap "$VISIBLE_GAP"
  sketchybar --bar hidden=off >/dev/null 2>&1 || true
}

hide_bar() {
  # Update the gap first so a concurrent AeroSpace reload + --sync sees the
  # new desired state and doesn't invert the bar/gap pairing.
  set_gap "$HIDDEN_GAP"
  sketchybar --bar hidden=on >/dev/null 2>&1 || true
}

sync_bar_to_gap() {
  local hidden_state
  hidden_state="$(get_hidden_state_from_gap)"

  if [[ "$hidden_state" == "on" ]]; then
    hide_bar
  else
    show_bar
  fi
}

toggle_bar_and_gap() {
  local hidden_state
  hidden_state="$(get_hidden_state)"

  if [[ "$hidden_state" == "on" ]]; then
    show_bar
  else
    hide_bar
  fi
}

case "$MODE" in
  --sync)
    sync_bar_to_gap
    ;;
  toggle|--toggle)
    toggle_bar_and_gap
    ;;
  *)
    echo "Usage: $0 [--sync|--toggle]" >&2
    exit 1
    ;;
esac
