# cachyos-configs

A small, public-friendly set of **CachyOS** desktop configuration files. This repository contains only the **minimal, hand-maintained** configs that are worth versioning; everything else is assumed to be generated automatically by the system, tools, or installers.

> License: **AGPL-v3.0**

---

## Repository Layout

```
.
├── alacritty/          # Terminal emulator
├── Code - OSS/         # VS Code OSS settings and extension list
├── fastfetch/          # System summary (neofetch-like)
├── Firefox/            # Browser prefs and extension list
├── fish/               # Shell configuration and functions
├── gtk-3.0/            # GTK3 theme/font preferences
├── gtk-4.0/            # GTK4 theme/font preferences
├── niri/               # Wayland compositor configuration
├── noctalia/           # Noctalia shell theme and settings
├── qt5ct/              # Qt5 control tool config
├── qt6ct/              # Qt6 control tool config
├── starship/           # Prompt configuration
└── vim/                # Vim configuration (HyDE-managed defaults + user overrides)
```

---

## What’s Included

This repo intentionally tracks only files that are:

* **Stable** (do not change on every machine reboot)
* **Portable** (safe to publish and reuse)
* **Human-maintained** (edited manually, not by GUI tools)

Included configurations:

* **Alacritty**: fonts, colors, padding, scrollback, key bindings
* **Code - OSS**:

  * `settings.json` (editor settings)
  * `extensions.txt` (reference list)

* **Fastfetch**: the printed “system summary” layout
* **Firefox**:

  * `user.js` (portable preferences)
  * `extensions.txt` (reference list)
  
* **Fish shell**:

  * main config
  * HyDE/XDG environment config
  * small helper functions (fzf navigation, yazi wrapper, etc.)
* **GTK 3/4**: theme/icon/font/cursor preferences
* **Niri**: input, keybinds, layout, misc settings (split into includes)
* **Noctalia**: color palette + settings files used by the shell
* **qt5ct/qt6ct**: Qt platform theme and UI behavior
* **Starship**: prompt layout
* **Vim**: HyDE defaults + user entrypoint

---

## What’s Not Included (By Design)

The following items are typically **not** tracked:

* Auto-generated cache/state files
* Machine-specific identifiers
* Window positions, recent files, MRU lists
* Any secrets (tokens, cookies, sync data)
* Anything that is better managed by a package manager or the OS

If you add more configs, keep the repo **clean and portable**.

---

## Install / Use

These configs are stored in the repository in a “portable” structure. To apply them, copy (or symlink) the relevant directories into your `$XDG_CONFIG_HOME` (usually `~/.config`).

### 1) Clone the repository

```bash
git clone https://github.com/<your-user>/cachyos-configs.git
cd cachyos-configs
```

### 2) Copy files (simple method)

```bash
cp -a alacritty "~/.config/"
cp -a fastfetch "~/.config/"
cp -a fish "~/.config/"
cp -a gtk-3.0 "~/.config/"
cp -a gtk-4.0 "~/.config/"
cp -a niri "~/.config/"
cp -a noctalia "~/.config/"
cp -a qt5ct "~/.config/"
cp -a qt6ct "~/.config/"
cp -a starship "~/.config/"
cp -a vim "~/.config/"

# Code - OSS (paths vary depending on distro/package)
# - You may prefer to merge these into your existing settings.
```

### 3) Symlink files (recommended for dotfiles)

Symlinks make updates trivial:

```bash
ln -sfn "$PWD/alacritty"  "$HOME/.config/alacritty"
ln -sfn "$PWD/fastfetch"  "$HOME/.config/fastfetch"
ln -sfn "$PWD/fish"       "$HOME/.config/fish"
ln -sfn "$PWD/gtk-3.0"    "$HOME/.config/gtk-3.0"
ln -sfn "$PWD/gtk-4.0"    "$HOME/.config/gtk-4.0"
ln -sfn "$PWD/niri"       "$HOME/.config/niri"
ln -sfn "$PWD/noctalia"   "$HOME/.config/noctalia"
ln -sfn "$PWD/qt5ct"      "$HOME/.config/qt5ct"
ln -sfn "$PWD/qt6ct"      "$HOME/.config/qt6ct"
ln -sfn "$PWD/starship"   "$HOME/.config/starship"
ln -sfn "$PWD/vim"        "$HOME/.config/vim"
```

> Tip: back up existing configs first if you already have them.

---

## Notes by Component

### Alacritty

* Location: `~/.config/alacritty/alacritty.toml`
* Includes key bindings aligned with the author’s workflow.

### Code - OSS

* `settings.json` contains editor/UI choices.
* `extensions.txt` is a **reference list** of extension IDs.

To install extensions from `extensions.txt`:

```bash
while read -r ext; do
  [ -z "$ext" ] && continue
  code --install-extension "$ext"
done < "Code - OSS/extensions.txt"
```

> Depending on your package, you may need `code-oss` instead of `code`.

### Firefox

* `user.js` must be placed into the **active Firefox profile directory** (next to `prefs.js`).
* `extensions.txt` is informational and can be used as a checklist.

### Fish

* Main file: `~/.config/fish/config.fish`
* Functions live under `~/.config/fish/functions/`

Some helpers assume these tools are installed:

* `eza` (directory listings)
* `fzf` (interactive selection)
* `bat` (previews)
* `yazi` (file manager)
* `duf` (disk usage)

### Niri

The config is split into topic-based files under `~/.config/niri/cfg/` and composed from `~/.config/niri/config.kdl`.

### Noctalia

Contains the theme palette and shell settings used by Noctalia.

### Vim

* `vimrc` is the user entrypoint.
* `hyde.vim` is marked as **HyDE-managed defaults**.

---

## Contributing

If you want to contribute:

* Keep changes **portable** and **documented**.
* Avoid machine-specific values.
* Do not commit anything that could be considered a secret.

Pull requests are welcome.

---

## License

This project is licensed under the **GNU Affero General Public License v3.0 (AGPL-v3.0)**.

If you redistribute or modify and provide it as a service, you must provide the source code under the same license.

---

## Contact

Email: **[cuso4ek55@gmail.com](mailto:cuso4ek55@gmail.com)**  
Email: **[zudin_daniil@mail.ru](mailto:zudin_daniil@mail.ru)**
