#!/usr/bin/env bash
# cachyos-configs installer
# Location: <repo-root>/scripts/install.sh
# Installs tracked configs into $XDG_CONFIG_HOME (default: ~/.config) with optional backup.
#
# This script manages only configs that map to ~/.config/<name>.
# Code - OSS and Firefox require manual steps (printed at the end).

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

MODE="symlink"        # symlink | copy
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
  --mode symlink|copy   Install mode. Default: symlink
  --dry-run             Print actions without changing anything
  --no-backup           Do not create backups (destructive)
  --backup-dir <path>   Override backup base directory
  -h, --help            Show this help

Examples:
  ./scripts/install.sh
  ./scripts/install.sh --mode copy
  ./scripts/install.sh --dry-run
EOF
}

log() { printf '%s\n' "$*"; }
run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] $*"
  else
    eval "$@"
  fi
}

die() { log "Error: $*"; exit 1; }

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --mode)
        [[ $# -ge 2 ]] || die "--mode requires a value"
        MODE="$2"
        shift 2
        ;;
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

  case "$MODE" in
    symlink|copy) ;;
    *) die "Invalid --mode: $MODE (use symlink or copy)" ;;
  esac
}

timestamp() { date +"%Y%m%d-%H%M%S"; }

backup_path_init() {
  local ts
  ts="$(timestamp)"
  echo "${BACKUP_BASE}/${ts}"
}

backup_one() {
  local dest="$1"
  local name="$2"
  local backup_dir="$3"

  [[ -e "$dest" || -L "$dest" ]] || return 0

  if [[ "$NO_BACKUP" -eq 1 ]]; then
    log " - remove: $dest"
    run "rm -rf -- \"${dest}\""
    return 0
  fi

  run "mkdir -p -- \"${backup_dir}\""
  log " - backup: $dest -> ${backup_dir}/${name}"
  run "mv -- \"${dest}\" \"${backup_dir}/${name}\""
}

install_one() {
  local name="$1"
  local src="${REPO_ROOT}/${name}"
  local dest="${XDG_CONFIG_HOME}/${name}"

  [[ -d "$src" ]] || die "Missing source directory: $src"

  log "Install: ${name}"
  backup_one "$dest" "$name" "$BACKUP_DIR"

  run "mkdir -p -- \"${XDG_CONFIG_HOME}\""

  case "$MODE" in
    symlink)
      log " - link:  $dest -> $src"
      run "ln -sfn -- \"${src}\" \"${dest}\""
      ;;
    copy)
      log " - copy:  $src -> $dest"
      run "cp -a -- \"${src}\" \"${dest}\""
      ;;
  esac
}

print_manual_steps() {
  cat <<EOF

Manual steps (not installed by this script)
-----------------------------------------

1) Code - OSS

Files in repo:
  - "${REPO_ROOT}/Code - OSS/settings.json"
  - "${REPO_ROOT}/Code - OSS/extensions.txt"

Typical settings path on Linux:
  - "\$XDG_CONFIG_HOME/Code - OSS/User/settings.json"
    (usually "~/.config/Code - OSS/User/settings.json")

Apply settings (create dirs if needed):
  mkdir -p "\$XDG_CONFIG_HOME/Code - OSS/User"
  cp -v "${REPO_ROOT}/Code - OSS/settings.json" "\$XDG_CONFIG_HOME/Code - OSS/User/settings.json"

Install extensions from list (choose your binary: code-oss or code):
  while IFS= read -r ext; do
    [ -z "\$ext" ] && continue
    code-oss --install-extension "\$ext" || code --install-extension "\$ext"
  done < "${REPO_ROOT}/Code - OSS/extensions.txt"

2) Firefox (user.js)

File in repo:
  - "${REPO_ROOT}/Firefox/user.js"

Place it into the ACTIVE Firefox profile directory (next to prefs.js).
How to find profile directory:
  - In Firefox: open "about:support" and click "Open Directory" next to "Profile Folder".

Then copy:
  cp -v "${REPO_ROOT}/Firefox/user.js" "<your-firefox-profile>/user.js"

Notes:
  - Firefox applies user.js on startup.
  - A profile-specific path is used; do not place user.js into ~/.config.

EOF
}

main() {
  parse_args "$@"

  [[ -d "$XDG_CONFIG_HOME" ]] || run "mkdir -p -- \"${XDG_CONFIG_HOME}\""

  BACKUP_DIR="$(backup_path_init)"
  log "Repo:        $REPO_ROOT"
  log "Config dir:  $XDG_CONFIG_HOME"
  log "Mode:        $MODE"
  if [[ "$NO_BACKUP" -eq 1 ]]; then
    log "Backup:      disabled"
  else
    log "Backup dir:  $BACKUP_DIR"
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "Dry-run:     enabled"
  fi
  log ""

  for name in "${CONFIG_DIRS[@]}"; do
    install_one "$name"
    log ""
  done

  print_manual_steps
  log "Done."
}

main "$@"