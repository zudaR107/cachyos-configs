#!/usr/bin/env bash
# cachyos-configs installer
# Location: <repo-root>/scripts/install.sh
#
# Scope
# -----
# - Interactively offer font and package installation.
# - Interactively offer SSH key and GPG key generation.
# - Write SSH and GPG configuration files only when the user agrees to key generation.
# - Interactively configure global Git identity and optional commit signing.
# - Interactively offer Windows/other OS detection via os-prober and GRUB config rebuild.
# - Interactively offer configuration migration for individual directories into ~/.config.
# - Interactively offer Code - OSS settings.json installation.
# - Interactively offer Code - OSS extension installation from the repository list.
# - Print a readable summary at the end.
#
# Behavior
# --------
# - Existing configuration directories are backed up only if the user chooses to install them.
# - Overlay copy keeps files that already exist on the system but are not present in the repo.
# - Package installation is opt-in per package.
# - Package order is logical: yay first, then pacman packages, then AUR packages.
# - Font cache is refreshed only if at least one font package was selected.
# - yay is installed only if selected or required by an AUR package.
# - Configuration migration is intentionally performed at the very end, after packages, keys and bootloader steps.
# - Code - OSS settings are installed only if explicitly selected by the user.
# - Code - OSS extensions are processed from the repo list, skipping comments and empty lines.
#
# Notes
# -----
# - This script is intended for CachyOS / Arch-based systems.
# - The font packages are handled in a dedicated section and are not repeated in the general package list.
# - If the GRUB step is selected, the script may update /etc/default/grub to enable os-prober.

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

DRY_RUN=0
NO_BACKUP=0
BACKUP_BASE="${XDG_STATE_HOME}/cachyos-configs-backup"
PACMAN_DB_SYNCED=0

CONFIG_ITEMS=(
  "alacritty|Alacritty"
  "fastfetch|Fastfetch"
  "fish|Fish shell"
  "gtk-3.0|GTK 3"
  "gtk-4.0|GTK 4"
  "niri|Niri"
  "noctalia|Noctalia"
  "qt5ct|Qt5ct"
  "qt6ct|Qt6ct"
  "starship|Starship"
  "vim|Vim"
)

FONT_PACKAGES=(
  "ttf-ubuntu-font-family"
  "ttf-ubuntu-mono-nerd"
)

PACKAGE_ITEMS=(
  "yay|aur-bootstrap"

  "telegram-desktop|pacman"
  "lazygit|pacman"
  "zip|pacman"
  "unzip|pacman"
  "unarchiver|pacman"
  "arm-none-eabi-gcc|pacman"
  "arm-none-eabi-gdb|pacman"
  "arm-none-eabi-binutils|pacman"
  "arm-none-eabi-newlib|pacman"
  "qtcreator|pacman"
  "lldb|pacman"
  "code|pacman"
  "yazi|pacman"
  "gnupg|pacman"
  "pinentry|pacman"
  "starship|pacman"
  "rsync|pacman"
  "cliphist|pacman"
  "wlsunset|pacman"
  "onefetch|pacman"
  "fastfetch|pacman"
  "stlink|pacman"
  "ex-vi-compat|pacman"
  "neovim|pacman"
  "pwgen|pacman"

  "onlyoffice-bin|aur"
  "amneziavpn-bin|aur"
)

STATS_CONFIG_PROMPTED=0
STATS_CONFIG_TOTAL=0
STATS_CONFIG_UPDATED=0
STATS_CONFIG_SKIPPED=0

STATS_BACKUPS=0
STATS_FILES_WRITTEN=0

STATS_FONT_PROMPTED=0
STATS_FONT_SELECTED=0
STATS_FONT_INSTALLED=0
STATS_FONT_ALREADY=0
STATS_FONT_FAILED=0
STATS_FONT_SKIPPED=0
STATS_FONT_CACHE_REFRESHED=0

STATS_PKG_PROMPTED=0
STATS_PKG_SELECTED=0
STATS_PKG_INSTALLED=0
STATS_PKG_ALREADY=0
STATS_PKG_FAILED=0
STATS_PKG_SKIPPED=0

STATS_SSH_GENERATED=0
STATS_SSH_REUSED=0
STATS_SSH_SKIPPED=0
STATS_SSH_CONFIG_WRITTEN=0

STATS_GPG_GENERATED=0
STATS_GPG_SKIPPED=0
STATS_GPG_CONFIG_WRITTEN=0

STATS_GIT_CONFIGURED=0
STATS_GIT_SIGNING_ENABLED=0

STATS_BOOT_PROMPTED=0
STATS_BOOT_SCANNED=0
STATS_BOOT_WINDOWS_FOUND=0
STATS_BOOT_GRUB_UPDATED=0
STATS_BOOT_SKIPPED=0
STATS_BOOT_FAILED=0

STATS_CODE_PROMPTED=0
STATS_CODE_INSTALLED=0
STATS_CODE_SKIPPED=0
STATS_CODE_FAILED=0

STATS_CODE_EXT_PROMPTED=0
STATS_CODE_EXT_SELECTED=0
STATS_CODE_EXT_INSTALLED=0
STATS_CODE_EXT_ALREADY=0
STATS_CODE_EXT_FAILED=0
STATS_CODE_EXT_SKIPPED=0

GIT_NAME=""
GIT_EMAIL=""
GIT_DEFAULT_BRANCH="main"
GENERATED_GPG_KEY_ID=""

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

log() {
  printf '%s\n' "$*"
}

log_section() {
  printf '\n==> %s\n' "$*"
}

log_info() {
  printf '  - %s\n' "$*"
}

log_warn() {
  printf '  ! %s\n' "$*" >&2
}

log_error() {
  printf '  x %s\n' "$*" >&2
}

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

run_shell() {
  local cmd="$1"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] bash -lc %q\n' "$cmd"
    return 0
  fi

  printf '+ bash -lc %q\n' "$cmd"
  bash -lc "$cmd"
}

run_cmd_capture() {
  local __outvar="$1"
  shift

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] '
    printf '%q ' "$@"
    printf '\n'
    printf -v "$__outvar" '%s' ""
    return 0
  fi

  printf '+ '
  printf '%q ' "$@"
  printf '\n'

  local output=""
  if output="$("$@")"; then
    printf -v "$__outvar" '%s' "$output"
    if [[ -n "$output" ]]; then
      printf '%s\n' "$output"
    fi
    return 0
  fi

  local status=$?
  printf -v "$__outvar" '%s' "$output"
  if [[ -n "$output" ]]; then
    printf '%s\n' "$output"
  fi
  return "$status"
}

die() {
  log_error "$*"
  exit 1
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

require_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
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

backup_copy_path() {
  local src="$1"
  local rel="$2"

  [[ "$NO_BACKUP" -eq 0 ]] || return 0
  path_exists "$src" || return 0

  local target
  target="$(unique_path "${BACKUP_DIR}/${rel}")"

  run_cmd mkdir -p -- "$(dirname -- "$target")"
  log_info "Backup: $src -> $target"
  run_cmd cp -a -- "$src" "$target"
  STATS_BACKUPS=$((STATS_BACKUPS + 1))
}

prepare_destination_dir() {
  local dest="$1"
  local backup_rel="$2"

  if ! path_exists "$dest"; then
    run_cmd mkdir -p -- "$dest"
    return 0
  fi

  if [[ -d "$dest" && ! -L "$dest" ]]; then
    return 0
  fi

  backup_copy_path "$dest" "$backup_rel"
  run_cmd rm -rf -- "$dest"
  run_cmd mkdir -p -- "$dest"
}

copy_tree_overlay() {
  local src="$1"
  local dest="$2"

  run_cmd mkdir -p -- "$dest"
  run_cmd cp -a -- "${src}/." "${dest}/"
}

write_text_file() {
  local path="$1"
  local rel="$2"
  local mode="$3"
  local content="$4"

  backup_copy_path "$path" "$rel"
  run_cmd mkdir -p -- "$(dirname -- "$path")"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] write file: %s\n' "$path"
  else
    printf '%s' "$content" > "$path"
    chmod "$mode" "$path"
  fi

  STATS_FILES_WRITTEN=$((STATS_FILES_WRITTEN + 1))
}

prompt_yes_no() {
  local prompt="$1"
  local default="${2:-n}"
  local reply

  while true; do
    if [[ "$default" == "y" ]]; then
      read -r -p "$prompt [Y/n]: " reply || true
      reply="${reply:-y}"
    else
      read -r -p "$prompt [y/N]: " reply || true
      reply="${reply:-n}"
    fi

    case "${reply,,}" in
      y|yes) return 0 ;;
      n|no)  return 1 ;;
      *) log_warn "Please answer yes or no." ;;
    esac
  done
}

prompt_value() {
  local prompt="$1"
  local default="${2:-}"
  local reply

  if [[ -n "$default" ]]; then
    read -r -p "$prompt [$default]: " reply || true
    reply="${reply:-$default}"
  else
    read -r -p "$prompt: " reply || true
  fi

  printf '%s\n' "$reply"
}

sync_pacman_db_once() {
  if [[ "$PACMAN_DB_SYNCED" -eq 0 ]]; then
    log_info "Synchronizing pacman package databases"
    run_cmd sudo pacman -Sy --noconfirm
    PACMAN_DB_SYNCED=1
  fi
}

is_package_installed() {
  local pkg="$1"
  pacman -Q "$pkg" >/dev/null 2>&1
}

install_pacman_package() {
  local pkg="$1"

  if is_package_installed "$pkg"; then
    log_info "Package already installed: $pkg"
    STATS_PKG_ALREADY=$((STATS_PKG_ALREADY + 1))
    return 0
  fi

  sync_pacman_db_once

  if run_cmd sudo pacman -S --needed --noconfirm "$pkg"; then
    log_info "Installed package: $pkg"
    STATS_PKG_INSTALLED=$((STATS_PKG_INSTALLED + 1))
    return 0
  fi

  log_error "Failed to install package: $pkg"
  STATS_PKG_FAILED=$((STATS_PKG_FAILED + 1))
  return 1
}

install_font_package() {
  local pkg="$1"

  if is_package_installed "$pkg"; then
    log_info "Font package already installed: $pkg"
    STATS_FONT_ALREADY=$((STATS_FONT_ALREADY + 1))
    return 0
  fi

  sync_pacman_db_once

  if run_cmd sudo pacman -S --needed --noconfirm "$pkg"; then
    log_info "Installed font package: $pkg"
    STATS_FONT_INSTALLED=$((STATS_FONT_INSTALLED + 1))
    return 0
  fi

  log_error "Failed to install font package: $pkg"
  STATS_FONT_FAILED=$((STATS_FONT_FAILED + 1))
  return 1
}

ensure_git_for_yay() {
  sync_pacman_db_once
  run_cmd sudo pacman -S --needed --noconfirm base-devel git
}

install_yay() {
  if command -v yay >/dev/null 2>&1; then
    log_info "yay is already installed"
    STATS_PKG_ALREADY=$((STATS_PKG_ALREADY + 1))
    return 0
  fi

  log_info "Installing build prerequisites for yay"
  ensure_git_for_yay

  local tmpdir
  tmpdir="$(mktemp -d)"

  if ! run_cmd git clone https://aur.archlinux.org/yay.git "${tmpdir}/yay"; then
    log_error "Failed to clone yay repository"
    STATS_PKG_FAILED=$((STATS_PKG_FAILED + 1))
    return 1
  fi

  if ! run_shell "cd '${tmpdir}/yay' && makepkg -si --noconfirm --needed"; then
    log_error "Failed to build/install yay"
    STATS_PKG_FAILED=$((STATS_PKG_FAILED + 1))
    return 1
  fi

  log_info "Installed package: yay"
  STATS_PKG_INSTALLED=$((STATS_PKG_INSTALLED + 1))
  return 0
}

ensure_yay_available() {
  if command -v yay >/dev/null 2>&1; then
    return 0
  fi

  if prompt_yes_no "Package requires yay. Install yay now?" "y"; then
    STATS_PKG_SELECTED=$((STATS_PKG_SELECTED + 1))
    install_yay
    return $?
  fi

  log_warn "Skipping AUR package because yay is not available"
  return 1
}

install_aur_package() {
  local pkg="$1"

  if is_package_installed "$pkg"; then
    log_info "Package already installed: $pkg"
    STATS_PKG_ALREADY=$((STATS_PKG_ALREADY + 1))
    return 0
  fi

  if ! ensure_yay_available; then
    STATS_PKG_SKIPPED=$((STATS_PKG_SKIPPED + 1))
    return 1
  fi

  if run_cmd yay -S --needed --noconfirm "$pkg"; then
    log_info "Installed package: $pkg"
    STATS_PKG_INSTALLED=$((STATS_PKG_INSTALLED + 1))
    return 0
  fi

  log_error "Failed to install package: $pkg"
  STATS_PKG_FAILED=$((STATS_PKG_FAILED + 1))
  return 1
}

install_config_dir() {
  local name="$1"
  local label="$2"
  local src="${REPO_ROOT}/${name}"
  local dest="${XDG_CONFIG_HOME}/${name}"

  [[ -d "$src" ]] || die "Missing source directory: $src"

  STATS_CONFIG_PROMPTED=$((STATS_CONFIG_PROMPTED + 1))

  if ! prompt_yes_no "Install config '${label}' into '${dest}'?" "n"; then
    log_info "Skipped config: $name"
    STATS_CONFIG_SKIPPED=$((STATS_CONFIG_SKIPPED + 1))
    return 0
  fi

  STATS_CONFIG_TOTAL=$((STATS_CONFIG_TOTAL + 1))

  log_info "Config: $name"
  backup_copy_path "$dest" "configs/${name}"

  if path_exists "$dest" && { [[ ! -d "$dest" ]] || [[ -L "$dest" ]]; }; then
    run_cmd rm -rf -- "$dest"
  fi

  prepare_destination_dir "$dest" "configs/${name}"
  copy_tree_overlay "$src" "$dest"
  STATS_CONFIG_UPDATED=$((STATS_CONFIG_UPDATED + 1))
}

install_configs_interactive() {
  log_section "Configuration directories"

  run_cmd mkdir -p -- "$XDG_CONFIG_HOME"

  local entry
  for entry in "${CONFIG_ITEMS[@]}"; do
    local name="${entry%%|*}"
    local label="${entry##*|}"
    install_config_dir "$name" "$label"
  done
}

install_code_oss_settings_interactive() {
  log_section "Code - OSS settings"

  STATS_CODE_PROMPTED=$((STATS_CODE_PROMPTED + 1))

  local src="${REPO_ROOT}/Code - OSS/settings.jsonc"
  local dest="${XDG_CONFIG_HOME}/Code - OSS/User/settings.json"

  if ! prompt_yes_no "Install Code - OSS settings.json into '${dest}'?" "n"; then
    log_info "Skipped Code - OSS settings"
    STATS_CODE_SKIPPED=$((STATS_CODE_SKIPPED + 1))
    return 0
  fi

  if [[ ! -f "$src" ]]; then
    log_error "Missing source file: $src"
    STATS_CODE_FAILED=$((STATS_CODE_FAILED + 1))
    return 1
  fi

  local content
  content="$(cat -- "$src")"

  write_text_file "$dest" "files/code-oss/settings.json" 644 "${content}"$'\n'
  STATS_CODE_INSTALLED=1
  log_info "Written Code - OSS settings: $dest"
  return 0
}

detect_code_cli() {
  if command -v code-oss >/dev/null 2>&1; then
    printf '%s\n' "code-oss"
    return 0
  fi

  if command -v code >/dev/null 2>&1; then
    printf '%s\n' "code"
    return 0
  fi

  return 1
}

is_code_extension_installed() {
  local cli="$1"
  local ext="$2"

  "$cli" --list-extensions 2>/dev/null | grep -Fxq -- "$ext"
}

install_code_extension() {
  local cli="$1"
  local ext="$2"

  if is_code_extension_installed "$cli" "$ext"; then
    log_info "Code - OSS extension already installed: $ext"
    STATS_CODE_EXT_ALREADY=$((STATS_CODE_EXT_ALREADY + 1))
    return 0
  fi

  if run_cmd "$cli" --install-extension "$ext"; then
    log_info "Installed Code - OSS extension: $ext"
    STATS_CODE_EXT_INSTALLED=$((STATS_CODE_EXT_INSTALLED + 1))
    return 0
  fi

  log_error "Failed to install Code - OSS extension: $ext"
  STATS_CODE_EXT_FAILED=$((STATS_CODE_EXT_FAILED + 1))
  return 1
}

install_code_oss_extensions_interactive() {
  log_section "Code - OSS extensions"

  local list_file="${REPO_ROOT}/Code - OSS/extensions.txt"

  if [[ ! -f "$list_file" ]]; then
    log_error "Missing extensions list: $list_file"
    STATS_CODE_EXT_FAILED=$((STATS_CODE_EXT_FAILED + 1))
    return 1
  fi

  local cli=""
  if ! cli="$(detect_code_cli)"; then
    log_error "Neither 'code-oss' nor 'code' command is available"
    STATS_CODE_EXT_FAILED=$((STATS_CODE_EXT_FAILED + 1))
    return 1
  fi

  local line=""
  local ext=""
  while IFS= read -r line <&3 || [[ -n "$line" ]]; do
    ext="${line#"${line%%[![:space:]]*}"}"
    ext="${ext%"${ext##*[![:space:]]}"}"

    [[ -n "$ext" ]] || continue
    [[ "${ext:0:1}" == "#" ]] && continue

    STATS_CODE_EXT_PROMPTED=$((STATS_CODE_EXT_PROMPTED + 1))

    if prompt_yes_no "Install Code - OSS extension '${ext}'?" "n"; then
      STATS_CODE_EXT_SELECTED=$((STATS_CODE_EXT_SELECTED + 1))
      install_code_extension "$cli" "$ext" || true
    else
      log_info "Skipped Code - OSS extension: $ext"
      STATS_CODE_EXT_SKIPPED=$((STATS_CODE_EXT_SKIPPED + 1))
    fi
  done 3< "$list_file"
}

install_fonts_interactive() {
  log_section "Font packages"

  local selected_any=0

  for pkg in "${FONT_PACKAGES[@]}"; do
    STATS_FONT_PROMPTED=$((STATS_FONT_PROMPTED + 1))

    if prompt_yes_no "Install font package '${pkg}'?" "n"; then
      STATS_FONT_SELECTED=$((STATS_FONT_SELECTED + 1))
      selected_any=1
      install_font_package "$pkg" || true
    else
      log_info "Skipped font package: $pkg"
      STATS_FONT_SKIPPED=$((STATS_FONT_SKIPPED + 1))
    fi
  done

  if [[ "$selected_any" -eq 1 ]]; then
    log_info "Refreshing font cache"
    if run_cmd fc-cache -f; then
      STATS_FONT_CACHE_REFRESHED=1
    else
      log_warn "Failed to refresh font cache"
    fi
  else
    log_info "No font package selected; font cache refresh skipped"
  fi
}

install_packages_interactive() {
  log_section "General packages"

  local entry
  for entry in "${PACKAGE_ITEMS[@]}"; do
    local pkg="${entry%%|*}"
    local source="${entry##*|}"

    STATS_PKG_PROMPTED=$((STATS_PKG_PROMPTED + 1))

    case "$source" in
      pacman)
        if prompt_yes_no "Install package '${pkg}' from pacman?" "n"; then
          STATS_PKG_SELECTED=$((STATS_PKG_SELECTED + 1))
          install_pacman_package "$pkg" || true
        else
          log_info "Skipped package: $pkg"
          STATS_PKG_SKIPPED=$((STATS_PKG_SKIPPED + 1))
        fi
        ;;
      aur-bootstrap)
        if prompt_yes_no "Install package '${pkg}' (AUR helper)?" "n"; then
          STATS_PKG_SELECTED=$((STATS_PKG_SELECTED + 1))
          install_yay || true
        else
          log_info "Skipped package: $pkg"
          STATS_PKG_SKIPPED=$((STATS_PKG_SKIPPED + 1))
        fi
        ;;
      aur)
        if prompt_yes_no "Install package '${pkg}' from AUR?" "n"; then
          STATS_PKG_SELECTED=$((STATS_PKG_SELECTED + 1))
          install_aur_package "$pkg" || true
        else
          log_info "Skipped package: $pkg"
          STATS_PKG_SKIPPED=$((STATS_PKG_SKIPPED + 1))
        fi
        ;;
      *)
        log_warn "Unknown package source for ${pkg}: ${source}"
        STATS_PKG_FAILED=$((STATS_PKG_FAILED + 1))
        ;;
    esac
  done
}

write_ssh_config() {
  log_section "SSH configuration"

  local ssh_config
  ssh_config=$(cat <<'EOF'
Host *
  ServerAliveInterval 30
  ServerAliveCountMax 3
  TCPKeepAlive yes
  AddKeysToAgent yes
  IdentitiesOnly yes
  HashKnownHosts yes
  StrictHostKeyChecking ask
  IdentityAgent $SSH_AUTH_SOCK

Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
EOF
)

  run_cmd mkdir -p -- "$HOME/.ssh"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    chmod 700 "$HOME/.ssh"
  fi

  write_text_file "$HOME/.ssh/config" "files/ssh/config" 600 "${ssh_config}"$'\n'
  STATS_SSH_CONFIG_WRITTEN=1
  log_info "Written ~/.ssh/config"
}

generate_ssh_key_interactive() {
  log_section "SSH key generation"

  if ! prompt_yes_no "Generate SSH key '~/.ssh/id_ed25519'?" "n"; then
    log_info "SSH key generation skipped"
    STATS_SSH_SKIPPED=$((STATS_SSH_SKIPPED + 1))
    return 0
  fi

  command -v ssh-keygen >/dev/null 2>&1 || die "ssh-keygen not found"

  write_ssh_config

  local key_path="$HOME/.ssh/id_ed25519"
  local key_pub="${key_path}.pub"
  local key_comment="$GIT_EMAIL"

  if [[ -z "$key_comment" ]]; then
    key_comment="$(prompt_value "SSH key comment (usually your email)" "")"
  fi

  run_cmd mkdir -p -- "$HOME/.ssh"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    chmod 700 "$HOME/.ssh"
  fi

  if path_exists "$key_path" || path_exists "$key_pub"; then
    if prompt_yes_no "SSH key already exists. Reuse existing key?" "y"; then
      log_info "Reusing existing SSH key"
      STATS_SSH_REUSED=$((STATS_SSH_REUSED + 1))
      return 0
    fi

    if ! prompt_yes_no "Overwrite existing SSH key files?" "n"; then
      log_info "SSH key generation skipped"
      STATS_SSH_SKIPPED=$((STATS_SSH_SKIPPED + 1))
      return 0
    fi

    backup_copy_path "$key_path" "files/ssh/id_ed25519"
    backup_copy_path "$key_pub" "files/ssh/id_ed25519.pub"
    run_cmd rm -f -- "$key_path" "$key_pub"
  fi

  log_info "ssh-keygen will now ask for the key passphrase"
  if run_cmd ssh-keygen -t ed25519 -C "$key_comment" -f "$key_path"; then
    log_info "Generated SSH key: $key_path"
    STATS_SSH_GENERATED=$((STATS_SSH_GENERATED + 1))
  else
    log_error "Failed to generate SSH key"
    STATS_SSH_SKIPPED=$((STATS_SSH_SKIPPED + 1))
  fi
}

write_gpg_agent_conf() {
  log_section "GPG agent configuration"

  local gpg_conf
  gpg_conf=$(cat <<'EOF'
pinentry-program /usr/bin/pinentry-curses
default-cache-ttl 2147483647
max-cache-ttl 2147483647
EOF
)

  run_cmd mkdir -p -- "$HOME/.gnupg"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    chmod 700 "$HOME/.gnupg"
  fi

  write_text_file "$HOME/.gnupg/gpg-agent.conf" "files/gnupg/gpg-agent.conf" 600 "${gpg_conf}"$'\n'
  STATS_GPG_CONFIG_WRITTEN=1
  log_info "Written ~/.gnupg/gpg-agent.conf"

  if command -v gpgconf >/dev/null 2>&1; then
    run_cmd gpgconf --kill gpg-agent || true
    run_cmd gpgconf --launch gpg-agent || true
  fi
}

ensure_gpg_dependencies() {
  local missing=0

  command -v gpg >/dev/null 2>&1 || missing=1
  [[ -x /usr/bin/pinentry-tty ]] || missing=1

  if [[ "$missing" -eq 0 ]]; then
    return 0
  fi

  log_warn "GPG prerequisites are missing (gnupg and/or pinentry-tty)"
  if prompt_yes_no "Install gnupg and pinentry now?" "y"; then
    STATS_PKG_SELECTED=$((STATS_PKG_SELECTED + 1))
    install_pacman_package "gnupg" || true
    STATS_PKG_SELECTED=$((STATS_PKG_SELECTED + 1))
    install_pacman_package "pinentry" || true
  fi

  command -v gpg >/dev/null 2>&1 || return 1
  [[ -x /usr/bin/pinentry-tty ]] || return 1
  return 0
}

list_gpg_secret_key_ids() {
  local filter="${1:-}"
  if [[ -n "$filter" ]]; then
    gpg --list-secret-keys --keyid-format=long --with-colons "$filter" 2>/dev/null | awk -F: '$1=="sec"{print $5}'
  else
    gpg --list-secret-keys --keyid-format=long --with-colons 2>/dev/null | awk -F: '$1=="sec"{print $5}'
  fi
}

detect_new_gpg_key_id() {
  local filter="$1"
  local before_file="$2"
  local after_file="$3"

  list_gpg_secret_key_ids "$filter" | sort -u > "$after_file"

  if [[ -s "$before_file" ]]; then
    comm -13 "$before_file" "$after_file" | tail -n1
  else
    tail -n1 "$after_file"
  fi
}

generate_gpg_key_interactive() {
  log_section "GPG key generation"

  if ! prompt_yes_no "Generate a new GPG key?" "n"; then
    log_info "GPG key generation skipped"
    STATS_GPG_SKIPPED=$((STATS_GPG_SKIPPED + 1))
    return 0
  fi

  if ! ensure_gpg_dependencies; then
    log_error "Cannot generate GPG key because prerequisites are missing"
    STATS_GPG_SKIPPED=$((STATS_GPG_SKIPPED + 1))
    return 1
  fi

  write_gpg_agent_conf

  if tty >/dev/null 2>&1; then
    export GPG_TTY
    GPG_TTY="$(tty)"
    gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1 || true
  fi

  local email_filter="$GIT_EMAIL"
  local before_file
  local after_file

  before_file="$(mktemp)"
  after_file="$(mktemp)"

  list_gpg_secret_key_ids "$email_filter" | sort -u > "$before_file"

  log_info "gpg will now open interactive key generation"
  log_info "Recommended choices: ECC -> Curve 25519, or your preferred algorithm"
  if ! run_cmd gpg --full-generate-key; then
    rm -f -- "$before_file" "$after_file"
    log_error "Failed to generate GPG key"
    STATS_GPG_SKIPPED=$((STATS_GPG_SKIPPED + 1))
    return 1
  fi

  GENERATED_GPG_KEY_ID="$(detect_new_gpg_key_id "$email_filter" "$before_file" "$after_file")"

  if [[ -z "$GENERATED_GPG_KEY_ID" ]]; then
    GENERATED_GPG_KEY_ID="$(list_gpg_secret_key_ids "$email_filter" | tail -n1)"
  fi

  rm -f -- "$before_file" "$after_file"

  if [[ -n "$GENERATED_GPG_KEY_ID" ]]; then
    log_info "Detected new GPG key ID: $GENERATED_GPG_KEY_ID"
    STATS_GPG_GENERATED=$((STATS_GPG_GENERATED + 1))
  else
    log_warn "GPG key was generated, but the key ID could not be detected automatically"
    STATS_GPG_GENERATED=$((STATS_GPG_GENERATED + 1))
  fi
}

ensure_git_available() {
  if command -v git >/dev/null 2>&1; then
    return 0
  fi

  log_warn "git is not installed"
  if prompt_yes_no "Install git now?" "y"; then
    sync_pacman_db_once
    run_cmd sudo pacman -S --needed --noconfirm git
  fi

  command -v git >/dev/null 2>&1
}

collect_git_identity() {
  log_section "Git identity"

  if ! prompt_yes_no "Configure global Git identity?" "n"; then
    log_info "Git configuration skipped"
    return 1
  fi

  if ! ensure_git_available; then
    log_error "git is not available"
    return 1
  fi

  local current_name current_email current_default_branch
  current_name="$(git config --global --get user.name || true)"
  current_email="$(git config --global --get user.email || true)"
  current_default_branch="$(git config --global --get init.defaultBranch || true)"

  GIT_NAME="$(prompt_value "Git user.name" "$current_name")"
  GIT_EMAIL="$(prompt_value "Git user.email" "$current_email")"

  if [[ -n "$current_default_branch" ]]; then
    GIT_DEFAULT_BRANCH="$(prompt_value "Git init.defaultBranch (default: main)" "$current_default_branch")"
  else
    GIT_DEFAULT_BRANCH="$(prompt_value "Git init.defaultBranch (default: main)" "main")"
  fi

  if [[ -z "$GIT_NAME" || -z "$GIT_EMAIL" ]]; then
    log_warn "Git name or email is empty; Git identity configuration skipped"
    return 1
  fi

  if [[ -z "$GIT_DEFAULT_BRANCH" ]]; then
    GIT_DEFAULT_BRANCH="main"
  fi

  return 0
}

configure_git() {
  if [[ -z "$GIT_NAME" || -z "$GIT_EMAIL" ]]; then
    return 1
  fi

  log_section "Writing Git configuration"

  run_cmd git config --global user.name "$GIT_NAME"
  run_cmd git config --global user.email "$GIT_EMAIL"
  run_cmd git config --global init.defaultBranch "$GIT_DEFAULT_BRANCH"

  if [[ -n "$GENERATED_GPG_KEY_ID" ]]; then
    run_cmd git config --global user.signingkey "$GENERATED_GPG_KEY_ID"
    run_cmd git config --global commit.gpgsign true
    run_cmd git config --global tag.gpgsign true
    run_cmd git config --global gpg.program gpg
    STATS_GIT_SIGNING_ENABLED=1
    log_info "Enabled Git commit/tag signing with GPG key: $GENERATED_GPG_KEY_ID"
  else
    log_info "No generated GPG key detected; Git signing settings were not enabled"
  fi

  STATS_GIT_CONFIGURED=1
  return 0
}

ensure_os_prober_available() {
  if command -v os-prober >/dev/null 2>&1; then
    return 0
  fi

  log_warn "os-prober is not installed"
  if prompt_yes_no "Install os-prober now?" "y"; then
    STATS_PKG_SELECTED=$((STATS_PKG_SELECTED + 1))
    install_pacman_package "os-prober" || true
  fi

  command -v os-prober >/dev/null 2>&1
}

detect_grub_cfg_path() {
  local candidates=(
    "/boot/grub/grub.cfg"
    "/boot/grub2/grub.cfg"
  )

  local path
  for path in "${candidates[@]}"; do
    if [[ -f "$path" ]]; then
      printf '%s\n' "$path"
      return 0
    fi
  done

  for path in "${candidates[@]}"; do
    if [[ -d "$(dirname -- "$path")" ]]; then
      printf '%s\n' "$path"
      return 0
    fi
  done

  return 1
}

ensure_grub_os_prober_enabled() {
  local grub_defaults="/etc/default/grub"

  if [[ ! -f "$grub_defaults" ]]; then
    log_warn "GRUB defaults file not found: $grub_defaults"
    return 1
  fi

  backup_copy_path "$grub_defaults" "system/etc/default/grub"

  local tmpfile
  tmpfile="$(mktemp)"

  if grep -Eq '^[[:space:]]*#?[[:space:]]*GRUB_DISABLE_OS_PROBER=' "$grub_defaults"; then
    sed -E 's/^[[:space:]]*#?[[:space:]]*GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' \
      "$grub_defaults" > "$tmpfile"
  else
    cat -- "$grub_defaults" > "$tmpfile"
    printf '\nGRUB_DISABLE_OS_PROBER=false\n' >> "$tmpfile"
  fi

  if cmp -s -- "$grub_defaults" "$tmpfile"; then
    log_info "GRUB os-prober setting is already enabled"
    rm -f -- "$tmpfile"
    return 0
  fi

  log_info "Enabling os-prober in /etc/default/grub"
  if run_cmd sudo install -m 644 -- "$tmpfile" "$grub_defaults"; then
    rm -f -- "$tmpfile"
    return 0
  fi

  rm -f -- "$tmpfile"
  return 1
}

run_bootloader_detection_interactive() {
  log_section "Windows detection and GRUB update"

  STATS_BOOT_PROMPTED=$((STATS_BOOT_PROMPTED + 1))

  if ! prompt_yes_no "Search for Windows/other OSes with os-prober and rebuild GRUB config?" "n"; then
    log_info "Bootloader step skipped"
    STATS_BOOT_SKIPPED=$((STATS_BOOT_SKIPPED + 1))
    return 0
  fi

  if ! ensure_os_prober_available; then
    log_error "Cannot continue because os-prober is unavailable"
    STATS_BOOT_FAILED=$((STATS_BOOT_FAILED + 1))
    return 1
  fi

  if ! command -v grub-mkconfig >/dev/null 2>&1; then
    log_error "grub-mkconfig not found; GRUB does not seem to be available"
    STATS_BOOT_FAILED=$((STATS_BOOT_FAILED + 1))
    return 1
  fi

  if ! ensure_grub_os_prober_enabled; then
    log_warn "Could not update /etc/default/grub; continuing anyway"
  fi

  local os_prober_output=""
  if run_cmd_capture os_prober_output sudo os-prober; then
    STATS_BOOT_SCANNED=$((STATS_BOOT_SCANNED + 1))
  else
    log_error "os-prober failed"
    STATS_BOOT_FAILED=$((STATS_BOOT_FAILED + 1))
    return 1
  fi

  if grep -qi 'windows' <<< "$os_prober_output"; then
    STATS_BOOT_WINDOWS_FOUND=1
    log_info "Windows installation detected by os-prober"
  elif [[ -n "$os_prober_output" ]]; then
    log_info "Other operating systems were detected, but Windows was not found"
  else
    log_warn "os-prober did not report any additional operating systems"
  fi

  local grub_cfg
  grub_cfg="$(detect_grub_cfg_path || true)"

  if [[ -z "$grub_cfg" ]]; then
    log_error "Could not determine GRUB config output path"
    STATS_BOOT_FAILED=$((STATS_BOOT_FAILED + 1))
    return 1
  fi

  log_info "Rebuilding GRUB configuration: $grub_cfg"
  if run_cmd sudo grub-mkconfig -o "$grub_cfg"; then
    STATS_BOOT_GRUB_UPDATED=1
    return 0
  fi

  log_error "Failed to rebuild GRUB configuration"
  STATS_BOOT_FAILED=$((STATS_BOOT_FAILED + 1))
  return 1
}

print_summary() {
  log_section "Summary"

  log "Configuration directories:"
  log "  Prompted:         ${STATS_CONFIG_PROMPTED}"
  log "  Selected:         ${STATS_CONFIG_TOTAL}"
  log "  Updated:          ${STATS_CONFIG_UPDATED}"
  log "  Skipped:          ${STATS_CONFIG_SKIPPED}"

  log ""
  log "Backups and files:"
  log "  Backups created:  ${STATS_BACKUPS}"
  log "  Files written:    ${STATS_FILES_WRITTEN}"

  log ""
  log "Fonts:"
  log "  Prompted:         ${STATS_FONT_PROMPTED}"
  log "  Selected:         ${STATS_FONT_SELECTED}"
  log "  Installed:        ${STATS_FONT_INSTALLED}"
  log "  Already present:  ${STATS_FONT_ALREADY}"
  log "  Failed:           ${STATS_FONT_FAILED}"
  log "  Skipped:          ${STATS_FONT_SKIPPED}"
  log "  Cache refreshed:  ${STATS_FONT_CACHE_REFRESHED}"

  log ""
  log "Packages:"
  log "  Prompted:         ${STATS_PKG_PROMPTED}"
  log "  Selected:         ${STATS_PKG_SELECTED}"
  log "  Installed:        ${STATS_PKG_INSTALLED}"
  log "  Already present:  ${STATS_PKG_ALREADY}"
  log "  Failed:           ${STATS_PKG_FAILED}"
  log "  Skipped:          ${STATS_PKG_SKIPPED}"

  log ""
  log "SSH:"
  log "  Config written:   ${STATS_SSH_CONFIG_WRITTEN}"
  log "  Keys generated:   ${STATS_SSH_GENERATED}"
  log "  Keys reused:      ${STATS_SSH_REUSED}"
  log "  Skipped:          ${STATS_SSH_SKIPPED}"

  log ""
  log "GPG:"
  log "  Config written:   ${STATS_GPG_CONFIG_WRITTEN}"
  log "  Keys generated:   ${STATS_GPG_GENERATED}"
  log "  Skipped:          ${STATS_GPG_SKIPPED}"

  log ""
  log "Git:"
  log "  Configured:       ${STATS_GIT_CONFIGURED}"
  log "  Default branch:   ${GIT_DEFAULT_BRANCH}"
  log "  Signing enabled:  ${STATS_GIT_SIGNING_ENABLED}"

  log ""
  log "Bootloader / dual-boot:"
  log "  Prompted:         ${STATS_BOOT_PROMPTED}"
  log "  Scans run:        ${STATS_BOOT_SCANNED}"
  log "  Windows found:    ${STATS_BOOT_WINDOWS_FOUND}"
  log "  GRUB updated:     ${STATS_BOOT_GRUB_UPDATED}"
  log "  Failed:           ${STATS_BOOT_FAILED}"
  log "  Skipped:          ${STATS_BOOT_SKIPPED}"

  log ""
  log "Code - OSS settings:"
  log "  Prompted:         ${STATS_CODE_PROMPTED}"
  log "  Installed:        ${STATS_CODE_INSTALLED}"
  log "  Failed:           ${STATS_CODE_FAILED}"
  log "  Skipped:          ${STATS_CODE_SKIPPED}"

  log ""
  log "Code - OSS extensions:"
  log "  Prompted:         ${STATS_CODE_EXT_PROMPTED}"
  log "  Selected:         ${STATS_CODE_EXT_SELECTED}"
  log "  Installed:        ${STATS_CODE_EXT_INSTALLED}"
  log "  Already present:  ${STATS_CODE_EXT_ALREADY}"
  log "  Failed:           ${STATS_CODE_EXT_FAILED}"
  log "  Skipped:          ${STATS_CODE_EXT_SKIPPED}"

  if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
    log ""
    log "SSH public key:"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      log "  [dry-run] ~/.ssh/id_ed25519.pub"
    else
      while IFS= read -r line; do
        log "  ${line}"
      done < "$HOME/.ssh/id_ed25519.pub"
    fi
  fi

  if [[ -n "$GENERATED_GPG_KEY_ID" ]]; then
    log ""
    log "Generated GPG key ID:"
    log "  ${GENERATED_GPG_KEY_ID}"
  fi

  log ""
  log "Please reboot the system after the script finishes."
}

main() {
  parse_args "$@"

  BACKUP_DIR="$(backup_path_init)"

  require_cmd cp
  require_cmd pacman

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

  install_fonts_interactive
  install_packages_interactive

  if collect_git_identity; then
    generate_ssh_key_interactive
    generate_gpg_key_interactive || true
    configure_git || true
  else
    generate_ssh_key_interactive
    generate_gpg_key_interactive || true
  fi

  run_bootloader_detection_interactive || true

  install_configs_interactive
  install_code_oss_settings_interactive || true
  install_code_oss_extensions_interactive || true

  print_summary
}

main "$@"
