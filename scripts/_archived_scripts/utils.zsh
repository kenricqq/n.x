# Wrapper Utils

hx() {
 if [ "$#" -gt 0 ]; then
   for f in "$@"; do
     realpath "$f" 2>/dev/null || print -r -- "$f"
   done > ~/.last_hx_files
 fi

 command hx "$@"
}

op() {
  file="$(head -n 1 ~/.last_hx_files 2>/dev/null)"

  if [ -z "$file" ]; then
    echo "no hx recent files"
    return 1
  fi

  command hx "$file"
}

opp() {
   if [ ! -s ~/.last_hx_files ]; then
     echo "no hx recent files"
     return 1
   fi

   file="$(fzf --prompt='hx recent> ' < ~/.last_hx_files)" || return
   [ -n "$file" ] && command hx "$file"
}

# zellij helpers
function zjr () { zellij run --name "$*" -- zsh -ic "$*";}
function zrf () { zellij run --name "$*" --floating -- zsh -ic "$*";}
function zri () { zellij run --name "$*" --in-place -- zsh -ic "$*";}
function zje () { zellij edit "$*";}
function zef () { zellij edit --floating "$*";}
function zei () { zellij edit --in-place "$*";}
function zpipe () {
  if [ -z "$1" ]; then
    zellij pipe;
  else
    zellij pipe -p $1;
  fi
}

function zi() {
	local result
	result=$(zoxide query -ls | while read -r score abs_path; do
		pretty_path="${abs_path/#$HOME/~}"
		echo -e "${score}\t${pretty_path}\t${abs_path}"
	done | fzf \
		--delimiter="\t" \
		--height 40% \
		--layout=reverse \
		--with-nth=1,2 \
		--preview='eza --icons auto --color=always --group-directories-first {3:q} 2>/dev/null || command ls -Cp {3:q}' \
		--preview-window="down,30%,sharp" \
		--bind 'enter:become(echo {3})')
	[ -n "$result" ] && cd "$result"
}

zi_widget() {
	zle -I
	zi
	zle reset-prompt
}
zle -N zi_widget
bindkey '^Z' zi_widget  # Ctrl-Z to trigger zoxide interactive

_zmx_list_pretty() {
  zmx list 2>/dev/null | while IFS=$'\t' read -r name pid clients created dir; do
    name="${name#"${name%%[![:space:]]*}"}"
    name=${name#name=}
    pid=${pid#pid=}
    clients=${clients#clients=}
    dir=${dir#start_dir=}
    printf "%-20s  pid:%-8s  clients:%-2s  %s\n" "$name" "$pid" "$clients" "$dir"
  done
}

_zmx_pick_session() {
  local selected
  selected=$(_zmx_list_pretty | fzf \
    --height=80% \
    --reverse \
    --prompt="zmx> " \
    --preview='zmx history {1} | tail -200' \
    --preview-window=right:60%:follow)
  [[ -n "$selected" ]] && echo "$selected" | awk '{print $1}'
}

zma() {
  local session_name="${1:-$(_zmx_pick_session)}"
  [[ -n "$session_name" ]] && zmx attach "$session_name"
}

zmr() {
  local session_name
  if (( $# > 1 )) && zmx list --short 2>/dev/null | grep -Fxq -- "$1"; then
    session_name="$1"
    shift
  else
    session_name="$(_zmx_pick_session)"
  fi
  [[ -n "$session_name" ]] || return 130
  if (( $# == 0 )); then
    echo "usage: zmr [session] command..." >&2
    return 2
  fi
  zmx run "$session_name" "$@"
}

zmh() {
  local session_name lines
  if [[ "$1" == <-> ]]; then
    session_name="$(_zmx_pick_session)"
    lines="$1"
  else
    session_name="${1:-$(_zmx_pick_session)}"
    lines="${2:-200}"
  fi
  [[ -n "$session_name" ]] && zmx history "$session_name" | tail -"$lines"
}

_accept_line_with_zoxide_fix() {
  local lead first trail

  if [[ $BUFFER =~ '^([[:space:]]*)(z[^[:space:]]+)([[:space:]]*)$' ]]; then
    lead=$match[1]
    first=$match[2]
    trail=$match[3]

    if [[ $first == z?* ]] && (( $+functions[z] )) && ! whence -w -- "$first" >/dev/null 2>&1; then
      BUFFER="${lead}z ${first#z}${trail}"
    fi
  fi

  if (( $+widgets[abbr-expand-and-accept] )); then
    zle abbr-expand-and-accept
  else
    zle .accept-line
  fi
}
zle -N accept-line _accept_line_with_zoxide_fix

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# JJ workspace helper: Worktrunk-ish ergonomics while staying jj-native.
_jj_ws_usage() {
  cat <<'EOF'
Usage:
  ws                              fzf-pick workspace and cd into it
  ws new <name> [base-rev]         create workspace and cd into it
  ws cd [name]                    cd to workspace; pick if omitted
  ws ls [--json]                  list workspaces
  ws root [name]                  print workspace root
  ws run [name] -- <cmd...>       run command in workspace; pick if name omitted
  ws pi [name] [-- prompt]        cd to workspace and launch pi; pick if omitted
  ws rm <name> [--delete]         forget workspace; delete files only with --delete
  ws stale                        jj workspace update-stale
  ws doctor                       check jj/ws environment

Env prototype config:
  WS_BASE=main@origin              default base for ws new
  WS_DIR='.ws'                    workspace dir template
  WS_PATH_TEMPLATE='{workspace}'   path template inside workspace dir
EOF
}

_jj_ws_config_path() {
  print -r -- "${XDG_CONFIG_HOME:-$HOME/.config}/ws/config.toml"
}

_jj_ws_current_name() {
  jj op log --no-graph --color never --limit 1 -T 'workspace_name' 2>/dev/null | sed 's/@$//'
}

_jj_ws_table() {
  local raw current_root repo_root current_name line_count name ws_path expected
  raw="$(jj workspace list -T 'name ++ "\t" ++ root ++ "\n"' 2>/dev/null)" || return
  current_root="$(jj root 2>/dev/null || true)"
  repo_root="$(_jj_ws_repo_root "$current_root")"
  current_name="$(printf '%s\n' "$raw" | awk -F '\t' -v root="$current_root" '$2 == root { print $1; exit }')"
  line_count="$(printf '%s\n' "$raw" | sed '/^$/d' | wc -l | tr -d ' ')"

  while IFS=$'\t' read -r name ws_path; do
    [[ -z "$name" ]] && continue
    if [[ "$ws_path" == \<Error:* && -n "$current_root" ]]; then
      if [[ "$name" == "default" ]]; then
        ws_path="$repo_root"
      elif [[ "$name" == "$current_name" || "$line_count" == 1 ]]; then
        ws_path="$current_root"
      elif [[ "${WS_DIR:-.ws}" == ".ws" ]]; then
        expected="$repo_root/.ws/$name"
        [[ -d "$expected" ]] && ws_path="$expected"
      fi
    fi
    printf '%s\t%s\n' "$name" "$ws_path"
  done <<< "$raw"
}

_jj_ws_names() {
  jj workspace list -T 'name ++ "\n"' 2>/dev/null
}

_jj_ws_pick() {
  local query="${1:-}" selected
  if [[ -z "$(jj root 2>/dev/null)" ]]; then
    echo "not inside a JJ repo" >&2
    return 1
  fi
  if ! command -v fzf >/dev/null 2>&1; then
    echo "fzf not found" >&2
    return 1
  fi

  selected="$(_jj_ws_names | fzf --query "$query" --height=40% --reverse --prompt='ws> ')"
  [[ -n "$selected" ]] || return 130
  print -r -- "$selected"
}

_jj_ws_path() {
  local name="$1"
  _jj_ws_table | awk -F '\t' -v name="$name" '$1 == name { print $2; exit }'
}

_jj_ws_root() {
  local name="${1:-}" ws_path
  if [[ -z "$name" ]]; then
    jj root 2>/dev/null
    return
  fi
  ws_path="$(_jj_ws_path "$name")"
  if [[ -z "$ws_path" ]]; then
    echo "workspace not found: $name" >&2
    echo "try: ws ls" >&2
    return 1
  fi
  if [[ "$ws_path" == \<Error:* ]]; then
    echo "workspace root unavailable: $name" >&2
    echo "$ws_path" >&2
    echo "likely stale workspace record; try: jj workspace forget $name" >&2
    return 1
  fi
  print -r -- "$ws_path"
}

_jj_ws_repo_root() {
  local root="${1:-$(jj root 2>/dev/null)}"
  if [[ "$root" == */.ws/* ]]; then
    print -r -- "${root%%/.ws/*}"
  else
    print -r -- "$root"
  fi
}

_jj_ws_primary_root() {
  local primary current_root
  primary="$(_jj_ws_table | awk -F '\t' '$1 == "default" { print $2; exit }')"
  if [[ -n "$primary" && "$primary" != \<Error:* ]]; then
    _jj_ws_repo_root "$primary"
    return
  fi

  current_root="$(jj root 2>/dev/null)" || return
  _jj_ws_repo_root "$current_root"
}

_jj_ws_expand_template() {
  local template="$1" workspace="${2:-}" primary repo result
  primary="$(_jj_ws_primary_root)" || return
  repo="${primary:t}"
  result="${template//\{repo\}/$repo}"
  result="${result//\{workspace\}/$workspace}"
  print -r -- "$result"
}

_jj_ws_abs_from_primary() {
  local input="$1" primary out
  primary="$(_jj_ws_primary_root)" || return
  if [[ "$input" == /* ]]; then
    out="$input"
  elif [[ "$input" == '~'* ]]; then
    out="${input/#\~/$HOME}"
  else
    out="$primary/$input"
  fi
  print -r -- "${out:A}"
}

_jj_ws_workspace_dir() {
  local template expanded
  template="${WS_DIR:-.ws}"
  expanded="$(_jj_ws_expand_template "$template")" || return
  _jj_ws_abs_from_primary "$expanded"
}

_jj_ws_dest() {
  local name="$1" dir template rel out
  dir="$(_jj_ws_workspace_dir)" || return
  template="${WS_PATH_TEMPLATE:-{workspace}}"
  rel="$(_jj_ws_expand_template "$template" "$name")" || return
  out="$dir/$rel"
  print -r -- "${out:A}"
}

_jj_ws_validate_name() {
  local name="$1"
  if [[ -z "$name" ]]; then
    echo "workspace name required" >&2
    return 1
  fi
  if [[ ! "$name" =~ '^[A-Za-z0-9._-]+$' || "$name" == .* || "$name" == *..* ]]; then
    echo "invalid workspace name: $name" >&2
    echo "use a simple name like: api-refactor" >&2
    return 1
  fi
}

_jj_ws_dir_empty() {
  [[ -d "$1" && -z "$(command find "$1" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]
}

_jj_ws_base_exists() {
  jj log -r "$1" --limit 1 >/dev/null 2>&1
}

_jj_ws_new() {
  local name="" base="${WS_BASE:-main@origin}" force=0 sparse="copy" arg dest existing

  while (( $# )); do
    arg="$1"
    case "$arg" in
      --base)
        shift
        base="${1:-}"
        ;;
      --force|-f)
        force=1
        ;;
      --empty-sparse)
        sparse="empty"
        ;;
      --full-sparse)
        sparse="full"
        ;;
      --copy-sparse)
        sparse="copy"
        ;;
      -h|--help)
        echo "usage: ws new <name> [base-rev] [--base <rev>] [--force] [--empty-sparse|--full-sparse|--copy-sparse]"
        return 0
        ;;
      --*)
        echo "unknown option: $arg" >&2
        return 2
        ;;
      *)
        if [[ -z "$name" ]]; then
          name="$arg"
        else
          base="$arg"
        fi
        ;;
    esac
    shift
  done

  _jj_ws_validate_name "$name" || return
  existing="$(_jj_ws_path "$name")"
  if [[ -n "$existing" ]]; then
    echo "workspace already exists: $name" >&2
    echo "try: ws cd $name" >&2
    return 1
  fi

  dest="$(_jj_ws_dest "$name")" || {
    echo "ws: not inside a JJ repo" >&2
    return 1
  }

  if [[ -e "$dest" ]]; then
    if (( ! force )) || ! _jj_ws_dir_empty "$dest"; then
      echo "destination exists: $dest" >&2
      echo "use --force only for an empty existing directory" >&2
      return 1
    fi
  fi

  if ! _jj_ws_base_exists "$base"; then
    echo "base revision not found: $base" >&2
    echo "set WS_BASE or pass: ws new $name --base <rev>" >&2
    return 1
  fi

  mkdir -p -- "${dest:h}" || return
  jj workspace add --name "$name" -r "$base" --sparse-patterns "$sparse" "$dest" || return
  builtin cd -- "$dest"
}

_jj_ws_cd() {
  local name="${1:-}" ws_path current_name
  if [[ -z "$name" ]]; then
    name="$(_jj_ws_pick)" || return
  fi
  ws_path="$(_jj_ws_root "$name")" || return
  if [[ "$ws_path" == \<Error:* ]]; then
    current_name="$(_jj_ws_current_name)"
    if [[ "$name" == "$current_name" ]]; then
      ws_path="$(jj root)" || return
    else
      echo "workspace has no recorded path: $name" >&2
      return 1
    fi
  fi
  builtin cd -- "$ws_path"
}

_jj_ws_list() {
  local format="${1:-}" current_root
  current_root="$(jj root 2>/dev/null || true)"
  if [[ -z "$current_root" ]]; then
    echo "not inside a JJ repo" >&2
    return 1
  fi
  if [[ "$format" == "--json" ]]; then
    CURRENT_ROOT="$current_root" python3 -c 'import json, os, sys
cur = os.path.realpath(os.environ.get("CURRENT_ROOT", ""))
rows = []
for line in sys.stdin:
    line = line.rstrip("\n")
    if not line:
        continue
    name, path = line.split("\t", 1)
    rows.append({"name": name, "path": path, "current": os.path.realpath(path) == cur, "stale": False})
print(json.dumps(rows, indent=2))' < <(_jj_ws_table)
    return
  fi

  printf '%-24s  %-60s  %-7s  %s\n' NAME PATH CURRENT STALE
  _jj_ws_table | while IFS=$'\t' read -r name ws_path; do
    [[ -z "$name" ]] && continue
    local current="no"
    [[ "${ws_path:A}" == "${current_root:A}" ]] && current="*"
    printf '%-24s  %-60s  %-7s  %s\n' "$name" "$ws_path" "$current" "?"
  done
}

_jj_ws_run() {
  local name="${1:-}" ws_path
  if [[ -z "$name" || "$name" == "--" ]]; then
    [[ "$name" == "--" ]] && shift
    name="$(_jj_ws_pick)" || return
  else
    shift
    [[ "${1:-}" == "--" ]] && shift
  fi
  if (( $# == 0 )); then
    echo "usage: ws run [name] -- <cmd...>" >&2
    return 2
  fi
  ws_path="$(_jj_ws_root "$name")" || return
  (builtin cd -- "$ws_path" && "$@")
}

_jj_ws_validate_delete_path() {
  local name="$1" ws_path="$2" force="${3:-0}" real home_real primary primary_real parent_real current_root current_real ws_dir ws_dir_real
  if [[ -z "$ws_path" ]]; then
    echo "refusing to delete empty path" >&2
    return 1
  fi
  if [[ ! -d "$ws_path" ]]; then
    echo "refusing to delete missing/non-directory path: $ws_path" >&2
    return 1
  fi

  real="${ws_path:A}"
  home_real="${HOME:A}"
  primary="$(_jj_ws_primary_root 2>/dev/null || true)"
  primary_real="${primary:A}"
  parent_real="${primary:h:A}"

  case "$real" in
    /|"$home_real"|"$primary_real"|"$parent_real")
      echo "refusing dangerous delete path: $real" >&2
      return 1
      ;;
  esac

  if (( ! force )); then
    if [[ "$name" == "default" || "$name" == "main" || "$name" == "master" ]]; then
      echo "refusing to delete main/default workspace: $name" >&2
      echo "use --force only if you know this is safe" >&2
      return 1
    fi

    current_root="$(jj root 2>/dev/null || true)"
    current_real="${current_root:A}"
    if [[ -n "$current_root" && "$current_real" == "$real" ]]; then
      echo "refusing to delete current workspace: $name" >&2
      echo "use --force only if you know this is safe" >&2
      return 1
    fi

    ws_dir="$(_jj_ws_workspace_dir)" || return
    ws_dir_real="${ws_dir:A}"
    if [[ "$real" != "$ws_dir_real"/* ]]; then
      echo "refusing to delete outside workspace dir: $real" >&2
      echo "workspace dir: $ws_dir_real" >&2
      echo "use --force only if you know this is safe" >&2
      return 1
    fi
  fi
}

_jj_ws_rm() {
  local delete=0 force=0 name="" arg ws_path current_root
  while (( $# )); do
    arg="$1"
    case "$arg" in
      --delete|-d)
        delete=1
        ;;
      --force|-f)
        force=1
        ;;
      --*)
        echo "unknown option: $arg" >&2
        return 2
        ;;
      *)
        name="$arg"
        ;;
    esac
    shift
  done

  if [[ -z "$name" ]]; then
    echo "usage: ws rm <name> [--delete] [--force]" >&2
    return 2
  fi

  ws_path="$(_jj_ws_root "$name")" || return
  echo "workspace: $name"
  echo "path: $ws_path"

  if (( delete )); then
    _jj_ws_validate_delete_path "$name" "$ws_path" "$force" || return
  fi

  jj workspace forget "$name" || return

  if (( delete )); then
    current_root="$(jj root 2>/dev/null || true)"
    if [[ -n "$current_root" && "${current_root:A}" == "${ws_path:A}" ]]; then
      builtin cd -- "${ws_path:h}" || return
    fi
    command rm -rf -- "$ws_path"
  else
    echo "left on disk: $ws_path"
  fi
}

_jj_ws_doctor() {
  echo "jj: $(command -v jj || echo missing)"
  jj --version 2>/dev/null || true
  echo "inside jj repo: $([[ -n "$(jj root 2>/dev/null)" ]] && echo yes || echo no)"
  echo "config path: $(_jj_ws_config_path)"
  echo "workspace dir: $(_jj_ws_workspace_dir 2>/dev/null || echo unavailable)"
  echo "base: ${WS_BASE:-main@origin}"
  if _jj_ws_base_exists "${WS_BASE:-main@origin}"; then
    echo "base exists: yes"
  else
    echo "base exists: no"
  fi
  echo "shell integration: function ws"
}

_jj_ws_pi() {
  local name="${1:-}" prompt ws_path
  if [[ -z "$name" || "$name" == "--" ]]; then
    [[ "$name" == "--" ]] && shift
    prompt="$*"
    name="$(_jj_ws_pick)" || return
  else
    shift
    [[ "${1:-}" == "--" ]] && shift
    prompt="$*"
  fi

  ws_path="$(_jj_ws_path "$name")"
  if [[ -n "$ws_path" ]]; then
    builtin cd -- "$ws_path" || return
  else
    _jj_ws_new "$name" || return
  fi

  if [[ -n "$prompt" ]]; then
    pi "$prompt"
  else
    pi
  fi
}

ws() {
  emulate -L zsh
  if (( $# == 0 )); then
    _jj_ws_cd
    return
  fi

  local cmd="$1"
  shift

  case "$cmd" in
    -h|--help|help)
      _jj_ws_usage
      ;;
    new)
      _jj_ws_new "$@"
      ;;
    cd)
      _jj_ws_cd "${1:-}"
      ;;
    ls)
      _jj_ws_list "${1:-}"
      ;;
    root)
      _jj_ws_root "${1:-}"
      ;;
    run)
      _jj_ws_run "$@"
      ;;
    pi)
      _jj_ws_pi "$@"
      ;;
    rm)
      _jj_ws_rm "$@"
      ;;
    stale)
      jj workspace update-stale
      ;;
    doctor)
      _jj_ws_doctor
      ;;
    *)
      echo "unknown ws command: $cmd" >&2
      echo "try: ws help" >&2
      return 2
      ;;
  esac
}

_ws_complete() {
  local -a commands names
  commands=(
    'new:create workspace'
    'cd:switch workspace; opens picker if omitted'
    'ls:list workspaces'
    'root:print workspace root'
    'run:run command in workspace'
    'pi:switch/create and launch pi'
    'rm:forget/delete workspace'
    'stale:update stale workspaces'
    'doctor:check setup'
    'help:show help'
  )
  if (( CURRENT == 2 )); then
    _describe 'command' commands
    return
  fi

  case "$words[2]" in
    cd|root|pi)
      if (( CURRENT == 3 )); then
        names=(${(f)"$(_jj_ws_names)"})
        compadd -a names
      else
        _message 'no more arguments'
      fi
      ;;
    rm)
      if (( CURRENT == 3 )); then
        names=(${(f)"$(_jj_ws_names)"})
        compadd -a names
      else
        compadd -- --delete --force
      fi
      ;;
    run)
      if (( CURRENT == 3 )); then
        names=(${(f)"$(_jj_ws_names)"})
        compadd -- --
        compadd -a names
      elif (( CURRENT == 4 )); then
        compadd -- --
      else
        _normal
      fi
      ;;
    new)
      if (( CURRENT > 3 )); then
        compadd -- --base --force --empty-sparse --full-sparse --copy-sparse
      else
        _message 'workspace name'
      fi
      ;;
    ls)
      compadd -- --json
      ;;
    *)
      _files
      ;;
  esac
}

if (( $+functions[compdef] )); then
  compdef _ws_complete ws
fi

 za() {
  z "$@" && ls -F
 }

ah() {
  local q="$*"
  alias | sed -E 's/^alias[[:space:]]+([^[:space:]]+)[[:space:]]+/\1|/' \
    | column -t -s '|' \
    | fzf --query "$q"
}

# alias selector, trigger with Ctrl-A
fzf_alias_widget() {
  local selected alias_name
  selected=$(
    awk '/^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*=/ {
      gsub(/^[[:space:]]+/, "");
      gsub(/[[:space:]]*;$/, "");
      print
    }' $HM/alias.nix | sort | fzf --prompt="Alias> "
  )
  alias_name=${selected%%=*}
  alias_name=${alias_name// /}
  if [[ -n $alias_name ]]; then
    LBUFFER="$alias_name"
    zle accept-line
  fi
}
zle -N fzf_alias_widget
bindkey '^A' fzf_alias_widget  # Ctrl-A to trigger

uf() {
  local file="$SCRIPTS/utils.zsh" fn
  [[ -r "$file" ]] || { echo "Can't read $file"; return 1; }

  fn=$(
    sed -nE 's/^[[:space:]]*(function[[:space:]]+)?([A-Za-z_][A-Za-z0-9_-]*)[[:space:]]*\([[:space:]]*\)[[:space:]]*\{.*$/\2/p' "$file" \
      | sort -u \
      | fzf --prompt='utils(function)> ' --height=40% --reverse
  ) || return

  typeset -f -- "$fn" >/dev/null || { echo "$fn not in session — source $file?"; return 1; }
  "$fn"
}

# UTILS FUNCTIONS + Keyboard Shortcuts

# go links with choose-gui
golc() {
  local f="$SCRIPTS/golinks.yaml" key url
  key=$(yq -r '.links|keys[]' "$f" | choose) || return
  url=$(KEY="$key" yq -er '.links[env(KEY)]' "$f") || return
  open "$url"
}

# go links
function gol() {
  local f="$SCRIPTS/golinks.yaml"
  yq -r '.links | to_entries[] | [.key, .value] | @tsv' "$f" |
  fzf --prompt='link> ' --with-nth=1 --delimiter=$'\t' \
      --preview 'printf %s {2}' --preview-window=right:50% \
      --bind 'enter:execute(open {2})+abort'
}

function rga-fzf() {
	RG_PREFIX="rga --files-with-matches"
	local file
	file="$(
		FZF_DEFAULT_COMMAND="$RG_PREFIX '$1'" \
			fzf --sort --preview="[[ ! -z {} ]] && rga --pretty --context 5 {q} {}" \
				--phony -q "$1" \
				--bind "change:reload:$RG_PREFIX {q}" \
				--preview-window="70%:wrap"
	)" &&
	echo "opening $file" &&
	hx "$file"
}

function colors() {
  for i in {0..255}; do
    print -Pn "%K{$i}  %k%F{$i}${(l:3::0:)i}%f "
    if (( i % 6 == 3 )); then
      print
    fi
  done
}

# aerospace functions
function fff() {
  aerospace list-windows --all | fzf --bind 'enter:execute(bash -c "aerospace focus --window-id {1}")+abort'
}

alias uuu="$EDITOR $SCRIPTS/use-utils"

# fuzzy dir search
function cdf() {
  local target

  target=$(fd --type f --type d --hidden | fzf --preview='
    if file --mime-type {} | rg -qF image/; then
      kitty icat --clear --transfer-mode=memory --stdin=no --place=30x30@0x0 {}
    else
      bat --color always --style numbers --theme TwoDark --line-range :200 {}
    fi'
  )

  if [[ -n "$target" ]]; then
      if [[ -d "$target" ]]; then
          cd "$target"
      else
          cd "$(dirname "$target")"
      fi
  fi
}

# Navigate dev/project folders
function dev() {
  project=$(ls $DEV | sk --prompt "Switch to project: ")
  [ -n "$project" ] && cd $DEV/$project && onefetch && y
}

function sv() {
  sv_proj=$(ls $PROJ_DIR/SvelteKit | sk --prompt "cd into project: ")
  [ -n "$sv_proj" ] && cd $PROJ_DIR/SvelteKit/$sv_proj && y
}

function pyproj() {
  py_proj=$(ls $PROJ_DIR/Python | sk --prompt "cd into project: ")
  [ -n "$py_proj" ] && cd $PROJ_DIR/Python/$py_proj && y
}

function rsproj() {
  rs_proj=$(ls $PROJ_DIR/Rust | sk --prompt "cd into project: ")
  [ -n "$rs_proj" ] && cd $PROJ_DIR/Rust/$rs_proj && y
}


# Google / Youtube
gg() { open "https://www.google.com/search?q=$(echo "$*" | sed 's/ /+/g')" }
yt() { open "https://www.youtube.com/results?search_query=$(echo "$*" | sed 's/ /+/g')" }

urls() {
  open "$(echo "$*" | sed 's/ /+/g')"
}

# md live preview
lv() {
  ls "$@" | entr -c glow "$@"
}

# yt music download
yt_music() {
  local url="$1"
  local output_dir="${2:-$HOME/KTQQ/media/audio}"
  local format="${3:-mp3}"

  if [[ -z "$url" ]]; then
    echo "Usage: yt_music <YouTube_URL> [output_directory] [audio_format]"
    echo "Example: yt_music 'https://youtube.com/watch?v=...' ~/Music mp3"
    return 1
  fi

  mkdir -p "$output_dir" || {
    echo "Error: Could not create output directory: $output_dir"
    return 1
  }

  yt-dlp \
    --extract-audio \
    --audio-format "$format" \
    --audio-quality 0 \
    --embed-thumbnail \
    --add-metadata \
    --restrict-filenames \
    --sponsorblock-remove sponsor,selfpromo,interaction \
    -o "$output_dir/%(title)s.%(ext)s" \
    "$url"
}

yt_vid() {
  # one simple flag: -s => download subtitles (en), prefer human, fallback to auto
  local want_subs=false
  local cleaned=()
  for a in "$@"; do [[ "$a" == "-s" ]] && want_subs=true || cleaned+=("$a"); done
  set -- "${cleaned[@]}"

  local url="$1"
  local output_dir="${2:-$HOME/KTQQ/media/video/watch-later}"

  if [[ -z "$url" ]]; then
    echo "Usage: yt_download [-s] <YouTube_URL> [output_directory]"
    return 1
  fi

  if ! command -v yt-dlp &>/dev/null; then
    echo "yt-dlp is not installed."
    return 1
  fi

  mkdir -p "$output_dir" || return 1

  # base yt-dlp command
  local args=(-f "bestvideo+bestaudio/best" -o "$output_dir/%(title)s.%(ext)s" --sponsorblock-remove sponsor,selfpromo,interaction)

  # add subs if -s was used
  if $want_subs; then
    args+=(--write-subs --write-auto-subs --sub-langs "en" --convert-subs srt)
  fi

  yt-dlp "${args[@]}" "$url"
}

function rst_md() {
  local f filename
  for f in *.rst(N); do
    filename="${f%.*}"
    echo "Converting $f to $filename.md"
    pandoc "$f" -f rst -t markdown -o "$filename.md"
  done
}
