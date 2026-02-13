# Requirements

This repository is primarily a collection of configuration files. Some of them assume that specific applications, fonts, and themes are installed.

This document lists the expected dependencies so the configs behave as intended.

> Notes
>
> * Package names can vary between distributions and AUR/third‑party repositories.
> * The list below is based on the tracked configs in this repo.

---

## Core applications

These are referenced directly by configuration files or key bindings.

* **Alacritty** (terminal)
* **Fish** (shell)
* **Starship** (prompt)
* **Fastfetch** (shell greeting/system summary)
* **Niri** (Wayland compositor)
* **Noctalia shell** (used by Niri keybinds via `qs -c noctalia-shell ...`)
* **Vim** (editor configuration; can also be used by Neovim with minor adjustments)

Optional but referenced by key bindings:

* **Firefox** (browser)
* **Code - OSS** (VS Code OSS build; keybind launches `code-oss` with a fallback to `code`)
* **Nautilus** (file manager)

---

## CLI tools used by Fish functions

Some Fish functions and aliases assume these tools exist.

Required for the configured workflow:

* **eza** — used by `cd.fish` and aliases for directory listing
* **fzf** — used by `ffcd`, `ffe`, `ffec`

Optional (features degrade gracefully if missing):

* **bat** — preview in `ffec`
* **yazi** — file manager used by the `y` wrapper
* **duf** — used by `df.fish`
* **openssh** — for `ssh-agent` usage

Developer tooling referenced in abbreviations (install if needed):

* **JLinkExe** — SEGGER J-Link tools
* **openocd** — flashing/debugging
* **make** (and your toolchain)

---

## Fonts

Configured in multiple places (Alacritty, Code - OSS, Qt5ct/Qt6ct, Firefox preferences).

* **Ubuntu Mono** (primary mono font)
* **Cantarell** (GTK font in `gtk-3.0/settings.ini` / `gtk-4.0/settings.ini`)

---

## Themes and icons

These are referenced in GTK and Qt configs.

GTK theme:

* **Material Sakura** (`gtk-theme-name=Material Sakura`)

Icon theme:

* **Tela-circle-dracula** (`gtk-icon-theme-name` and Qt icon theme)

Cursor theme:

* **Bibata-Modern-Ice** (`gtk-cursor-theme-name`)

Qt style:

* **Fusion** (Qt widget style)

Qt platform theme selection:

* **qt6ct** is selected in `niri/cfg/misc.kdl` via `QT_QPA_PLATFORMTHEME=qt6ct`.

  * Install **qt6ct** for Qt6 applications.
  * `qt5ct` is tracked for Qt5 apps.

---

## Wayland session expectations

The Niri configs assume a Wayland session and export:

* `XDG_SESSION_TYPE=wayland`
* `XDG_CURRENT_DESKTOP=niri`

Qt is forced to Wayland (`QT_QPA_PLATFORM=wayland`) and client-side decorations are disabled (`QT_WAYLAND_DISABLE_WINDOWDECORATION=1`).

Electron apps are allowed to auto-select the platform via:

* `ELECTRON_OZONE_PLATFORM_HINT=auto`

---

## Arch / CachyOS install hints

Use these as a starting point. Adjust package names to your setup.

Example (system packages):

```bash
sudo pacman -S --needed \
  alacritty fish starship fastfetch \
  fzf eza bat yazi duf \
  firefox \
  nautilus \
  qt5ct qt6ct
```

For Niri / Noctalia / themes/icons/cursors/fonts, you may need AUR or a dedicated repository depending on what you use.

---

## Minimal vs full setup

If you want the smallest working subset:

* Fish + Starship
* Fastfetch
* Alacritty
* Niri (if you use the Wayland setup)

For the “full experience” as configured:

* Noctalia shell
* Themes/icons/cursor + fonts
* eza + fzf (+ bat/yazi/duf)
* Code - OSS / Firefox / Nautilus
