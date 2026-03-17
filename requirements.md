# Requirements

This repository is a collection of desktop and application configuration files. Many of them assume that specific applications, helper tools, fonts, themes, and a Wayland session are already available.

This document describes the expected runtime environment so the tracked configs behave as intended.

> Notes
>
> * Package names can vary between distributions.
> * Some components may come from official repositories, AUR, or project-specific installation methods.
> * This file reflects the current state of the tracked configs and the included `scripts/bootstrap.sh` helper.

---

## Target environment

This setup is primarily intended for:

* **CachyOS / Arch-based Linux**
* **Wayland**
* **Niri** as the compositor / window manager
* **Noctalia shell** for desktop shell components

A different environment may still work partially, but the full setup assumes the stack above.

---

## Core applications

These applications are referenced directly by configuration files, startup logic, shell config, or Niri key bindings.

### Core desktop and shell stack

* **Niri** — main Wayland compositor
* **Noctalia shell** — shell components used by launcher, lock screen, volume, brightness, media, and session menu actions
* **Fish** — main shell
* **Starship** — prompt engine
* **Alacritty** — terminal emulator
* **Fastfetch** — terminal system summary shown from Fish greeting

### Configured applications

* **Firefox** — browser launched from Niri key bindings
* **Code - OSS** or **code** — editor launched from Niri key bindings and used by the tracked settings
* **Nautilus** — file manager launched from Niri key bindings
* **Vim** — configured by the files under `vim/`

### Optional but referenced by the repository

* **qt5ct** — for Qt5 theming
* **qt6ct** — for Qt6 theming and selected as the Qt platform theme

---

## CLI tools used by Fish config and helpers

The Fish configuration and helper functions reference the following tools.

### Strongly recommended

These are part of the intended workflow.

* **eza** — used by aliases and by `cd.fish` / `y.fish` for directory listing
* **fzf** — used by `ffcd`, `ffe`, and `ffec`
* **yazi** — used by the `y` wrapper function
* **fastfetch** — used by the `hello` greeting function
* **openssh** — required for `ssh-agent` / `ssh-keygen` workflows

### Optional but supported by the current functions

* **bat** — preview command in `ffec`
* **duf** — used by `df.fish`

### Runtime tools referenced by shell or desktop behavior

* **ssh-agent** — started from Fish when no agent socket is available
* **wl-paste** — referenced by Noctalia clipboard history commands
* **cliphist** — referenced by Noctalia clipboard history commands
* **wlsunset** — included in the bootstrap package list and commonly used alongside Wayland desktop setups

---

## Desktop utilities referenced by Noctalia or Niri

The current Noctalia settings and Niri key bindings assume these tools or integrations exist.

* **qs / noctalia-shell** — required for launcher, lock screen, session menu, brightness, volume, media, and other shell IPC actions
* **pwvucontrol** or **pavucontrol** — middle-click action for the Noctalia volume widget
* **cliphist** — clipboard history backend for the launcher

If these are missing, some shell widgets, actions, or key bindings will not behave as configured.

---

## Developer tools referenced by shell abbreviations or bootstrap script

These are not required for the desktop itself, but they are referenced by the tracked shell config or by the bootstrap script.

### Referenced by Fish abbreviations

* **JLinkExe** — SEGGER J-Link CLI
* **openocd** — flashing / debugging
* **make** — used by `m` / `mc` abbreviations
* **git** — used by abbreviations and bootstrap logic
* **lazygit** — referenced by the `lg` abbreviation

### Referenced by the bootstrap script package list

* **gnupg**
* **pinentry**
* **rsync**
* **tree**
* **zip**, **unzip**, **unarchiver**
* **onefetch**
* **stlink**
* **neovim**
* **pwgen**
* **lldb**
* **qtcreator**
* **arm-none-eabi-gcc**
* **arm-none-eabi-gdb**
* **arm-none-eabi-binutils**
* **arm-none-eabi-newlib**
* **telegram-desktop**
* **onlyoffice-bin** (AUR)
* **amneziavpn-bin** (AUR)

These packages are not all required for using the configs, but they are part of the current bootstrap script and represent the intended workstation setup.

---

## Fonts

The current configs reference these fonts directly.

### Required fonts

* **Ubuntu Mono** — used in Alacritty, Code - OSS, Qt5ct/Qt6ct, and Vim-related workflow
* **Cantarell** — used in GTK settings

### Bootstrap-managed font packages

The bootstrap script currently offers:

* `ttf-ubuntu-font-family`
* `ttf-ubuntu-mono-nerd`

The Nerd Font package is especially useful for icons and glyph-rich terminal tools.

---

## Themes, icons, and cursor theme

These values are referenced directly by GTK and Qt configs.

### GTK theme

* **Material Sakura**

### Icon theme

* **Tela-circle-dracula**

### Cursor theme

* **Bibata-Modern-Ice**

### Qt widget style

* **Fusion**

If these are missing, applications will still run, but the visual result will differ from the screenshots and intended setup.

---

## Qt and Wayland expectations

The Niri config exports and assumes the following environment behavior.

### Session

* `XDG_SESSION_TYPE=wayland`
* `XDG_CURRENT_DESKTOP=niri`

### Qt

* `QT_QPA_PLATFORM=wayland`
* `QT_WAYLAND_DISABLE_WINDOWDECORATION=1`
* `QT_QPA_PLATFORMTHEME=qt6ct`

This means:

* Qt applications are expected to run on Wayland
* client-side decorations are intentionally disabled
* Qt6 theming is expected to go through **qt6ct**
* Qt5 apps can still use the tracked `qt5ct` config

### Electron

* `ELECTRON_OZONE_PLATFORM_HINT=auto`

Electron applications are allowed to auto-select the best platform backend.

---

## Code - OSS notes

The repository stores:

* `Code - OSS/settings.jsonc`
* `Code - OSS/extensions.txt`

Expected behavior:

* the file is tracked as `settings.jsonc` so it can remain documented with comments
* when installed into Code - OSS, it normally becomes `settings.json`
* the extension list is a reference/install source, not a lock file

The bootstrap script can also install the settings file and optionally offer extensions one by one.

---

## Firefox notes

The repository stores:

* `Firefox/user.js`
* `Firefox/extensions.txt`

Expected behavior:

* `user.js` must be copied into the active Firefox profile directory, next to `prefs.js`
* `extensions.txt` is informational and can be used as a checklist

Firefox itself is also referenced by Niri key bindings.

---

## Bootstrap script coverage

The included `scripts/bootstrap.sh` script currently supports:

* interactive font installation
* interactive package installation
* SSH key generation and SSH config writing
* GPG key generation and `gpg-agent.conf` writing
* global Git identity setup
* optional Git signing setup when a GPG key is generated
* optional `os-prober` / GRUB integration
* interactive installation of selected config directories into `~/.config`
* optional installation of Code - OSS settings and extensions

This means the repository is usable either:

* manually, by copying or symlinking files, or
* semi-automatically, through the bootstrap script

---

## Minimal setup vs intended full setup

### Minimal usable subset

A smaller subset can still be useful:

* Fish
* Starship
* Alacritty
* Fastfetch
* eza
* fzf

### Intended full setup

For the desktop shown in the screenshots, the intended setup is closer to:

* Niri
* Noctalia shell
* Fish + Starship
* Alacritty + Fastfetch
* GTK / Qt theming
* Firefox
* Code - OSS
* Nautilus
* eza + fzf + yazi + bat + duf
* the configured fonts, theme, icon theme, and cursor theme

---

## Example package starting point for Arch / CachyOS

Adjust package names to your environment.

```bash
sudo pacman -S --needed \
  alacritty fish starship fastfetch \
  eza fzf bat yazi duf \
  firefox nautilus \
  qt5ct qt6ct \
  gnupg pinentry openssh cliphist
```

Additional desktop components such as **Niri**, **Noctalia**, themes, icons, cursor themes, and some packages from the bootstrap script may require AUR packages, project repositories, or manual installation.

---

## Final note

This repository is a curated config set, not a universal distro profile.

If you reuse parts of it, treat this document as a guide to the expected environment rather than a strict lockfile.
