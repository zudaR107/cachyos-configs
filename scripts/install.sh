#!/usr/bin/env bash
# cachyos-configs installer
# Location: <repo-root>/scripts/install.sh
#
# Behavior
# --------
# - Back up existing config directories before any changes.
# - Overlay-copy tracked config directories into $XDG_CONFIG_HOME.
# - Existing files with the same path are overwritten by repo versions.
# - Existing files that are NOT present in the repo are kept as-is.
#
# This is intentionally an "overlay copy" installer:
# it merges repo contents into existing config directories instead of replacing them.
#
# Requirements
# ------------
# - rsync
#
# Notes
# -----
# - This script manages only configs that map to ~/.config/<name>.
# - Code - OSS and Firefox require manual steps (printed at the end).

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

DRY_RUN=0
NO_BACKUP=0
BACKUP_BASE="${XDG_STATE_HOME}/cachyos-configs-backup"

CONFIG_DIRS=(
  "alacritty"
  "fastfetch"
  "fish"
  "gtk-3.0"
  "gtk-4.0"
  "niri"
  "noctalia"
  "qt5ct"
  "qt6ct"
  "starship"
  "vim"
)

usage() {
  cat <<'EOF'
Usage:
  ./scripts/install.sh [options]

Options:
  --dry-run             Print actions without changing anything
  --no-backup           Do not create backups
  --backup-dir <path>   Override backup base directory
  -h, --help            Show this help

Examples:
  ./scripts/install.sh
  ./scripts/install.sh --dry-run
  ./scripts/install.sh --backup-dir "$HOME/backups/cachyos-configs"
EOF
}

log() { printf '%s\n' "$*"; }

run_cmd() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] '
    printf '%q ' "$@"
    printf '\n'
    return 0
  fi

  printf '+ '
  printf '%q ' "$@"
  printf '\n'
  "$@"
}

die() {
  log "Error: $*"
  exit 1
}

require_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      --no-backup)
        NO_BACKUP=1
        shift
        ;;
      --backup-dir)
        [[ $# -ge 2 ]] || die "--backup-dir requires a path"
        BACKUP_BASE="$2"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "Unknown argument: $1"
        ;;
    esac
  done
}

timestamp() {
  date +"%Y%m%d-%H%M%S"
}

backup_path_init() {
  local ts
  ts="$(timestamp)"
  printf '%s/%s\n' "$BACKUP_BASE" "$ts"
}

path_exists() {
  local p="$1"
  [[ -e "$p" || -L "$p" ]]
}

unique_path() {
  local base="$1"

  if ! path_exists "$base"; then
    printf '%s\n' "$base"
    return 0
  fi

  local i=1
  while :; do
    local candidate="${base}.dup${i}"
    if ! path_exists "$candidate"; then
      printf '%s\n' "$candidate"
      return 0
    fi
    i=$((i + 1))
  done
}

backup_one() {
  local dest="$1"
  local name="$2"

  [[ "$NO_BACKUP" -eq 0 ]] || return 0
  path_exists "$dest" || return 0

  run_cmd mkdir -p -- "$BACKUP_DIR"

  local backup_target
  backup_target="$(unique_path "${BACKUP_DIR}/${name}")"

  log " - backup: $dest -> $backup_target"
  run_cmd cp -a -- "$dest" "$backup_target"
}

prepare_destination() {
  local dest="$1"

  if ! path_exists "$dest"; then
    run_cmd mkdir -p -- "$dest"
    return 0
  fi

  if [[ -d "$dest" && ! -L "$dest" ]]; then
    return 0
  fi

  log " - destination is not a real directory: $dest"

  if [[ "$NO_BACKUP" -eq 0 ]]; then
    local base_name
    base_name="$(basename -- "$dest")"
    backup_one "$dest" "$base_name"
  fi

  run_cmd rm -rf -- "$dest"
  run_cmd mkdir -p -- "$dest"
}

install_one() {
  local name="$1"
  local src="${REPO_ROOT}/${name}"
  local dest="${XDG_CONFIG_HOME}/${name}"

  [[ -d "$src" ]] || die "Missing source directory: $src"

  log "Install: ${name}"

  backup_one "$dest" "$name"
  prepare_destination "$dest"

  log " - overlay copy: $src/ -> $dest/"
  run_cmd rsync -a -- "${src}/" "${dest}/"
}

print_manual_steps() {
  cat <<EOF

Manual steps (not installed by this script)
-----------------------------------------

1) Code - OSS

Files in repo:
  - "${REPO_ROOT}/Code - OSS/settings.jsonc"
  - "${REPO_ROOT}/Code - OSS/extensions.txt"

Typical settings path on Linux:
  - "\$XDG_CONFIG_HOME/Code - OSS/User/settings.json"

Apply settings:
  mkdir -p "\$XDG_CONFIG_HOME/Code - OSS/User"
  cp -v "${REPO_ROOT}/Code - OSS/settings.jsonc" "\$XDG_CONFIG_HOME/Code - OSS/User/settings.json"

Install extensions:
  while IFS= read -r ext; do
    [ -z "\$ext" ] && continue
    code-oss --install-extension "\$ext" 2>/dev/null || code --install-extension "\$ext"
  done < "${REPO_ROOT}/Code - OSS/extensions.txt"

2) Firefox (user.js)

File in repo:
  - "${REPO_ROOT}/Firefox/user.js"

Place it into the active Firefox profile directory.

Then copy:
  cp -v "${REPO_ROOT}/Firefox/user.js" "<your-firefox-profile>/user.js"

EOF
}

main() {
  parse_args "$@"
  require_cmd rsync

  BACKUP_DIR="$(backup_path_init)"

  log "Repo:        $REPO_ROOT"
  log "Config dir:  $XDG_CONFIG_HOME"
  if [[ "$NO_BACKUP" -eq 1 ]]; then
    log "Backup:      disabled"
  else
    log "Backup dir:  $BACKUP_DIR"
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "Dry-run:     enabled"
  fi
  log ""

  run_cmd mkdir -p -- "$XDG_CONFIG_HOME"

  for name in "${CONFIG_DIRS[@]}"; do
    install_one "$name"
    log ""
  done

  print_manual_steps
  log "Done."
}

main "$@"
