# Contributing to cachyos-configs

Thanks for considering a contribution.

This repository is a curated set of desktop and application configuration files for a **CachyOS / Arch-like Wayland setup** built around **Niri**, **Noctalia**, **Fish**, **Alacritty**, **Starship**, **GTK/Qt theming**, **Firefox**, **Code - OSS**, and a small **Vim** setup.

The goal is not to version an entire home directory, but to keep a small, portable, public-friendly collection of configs that are actually worth tracking.

---

## Goals

Contributions should help keep the repository:

* **portable**
* **safe to publish**
* **easy to review**
* **easy to maintain**
* **aligned with the current desktop stack and repository style**

---

## What We Accept

Good contributions include:

* improvements to existing tracked configs
* documentation updates (`README.md`, `requirements.md`, `CONTRIBUTING.md`, changelog, screenshots)
* cleanup that improves readability or portability
* small additions that fit the current scope of the repository
* improvements to repository hygiene, CI, or the bootstrap script
* stable, reviewable GUI-generated config files when they are useful and intentionally tracked

---

## What We Do Not Accept

Please do not contribute:

* secrets or sensitive data

  * tokens
  * cookies
  * private URLs
  * credentials
  * SSH private keys
  * GPG private keys
* machine-specific junk

  * cache files
  * history files
  * recent file lists
  * window geometry dumps
  * timestamps and other noisy state
* random files from a full `~/.config` copy
* large binaries, theme bundles, archives, or vendor dumps
* changes that make the repo harder to understand than the value they add

---

## Repository Scope

This repository currently focuses on:

* desktop and shell config (`niri`, `noctalia`, `fish`, `starship`, `alacritty`, `fastfetch`)
* appearance config (`gtk-3.0`, `gtk-4.0`, `qt5ct`, `qt6ct`)
* selected application config (`Firefox`, `Code - OSS`, `vim`)
* helper repository files (`assets`, CI, issue templates, bootstrap script, docs)

When proposing something new, ask:

* does it belong to the current setup?
* is it stable enough to version?
* is it safe to publish?
* is it understandable without private local context?

If the answer is mostly “no”, it probably does not belong here.

---

## Repository Structure

General layout rules:

* keep config files grouped by application at the top level
* keep repository support files in their existing locations:

  * `.github/` for templates and workflows
  * `assets/` for screenshots and visual repository assets
  * `scripts/` for helper scripts such as the bootstrap script
* prefer smaller, topic-based config files when the target tool supports includes
* do not reorganize the repo structure without a strong reason

---

## Style Guidelines

### Comments and documentation

* Write comments in **English**.
* Keep comments **documentation-like** and focused on intent.
* Prefer explaining **why** a setting exists over repeating what the syntax already says.
* Add a `Location:` comment near the top **when the file format supports comments**.
* Do not force comment-style metadata into strict formats that do not support comments, such as plain JSON.

### Formatting

* Use **LF** line endings.
* Avoid trailing whitespace.
* Ensure text files end with a final newline.
* Keep formatting consistent with the file format and surrounding file style.
* Do not reformat unrelated files just because you touched the repository.

### Portability rules

* Avoid absolute paths outside of `$HOME` unless there is a strong reason.
* Avoid machine-specific identifiers unless they are required and intentionally reviewed.
* Do not add personal data unless the config format genuinely needs it.
* Treat GUI-generated files carefully: they are acceptable only when they are stable, readable enough, and useful to keep.

---

## Scripts and automation

This repository includes `scripts/bootstrap.sh`, which is intentionally interactive.

When changing the bootstrap script:

* keep behavior understandable and reviewable
* avoid adding heavy or surprising dependencies unless necessary
* do not turn it into a silent one-shot installer
* keep destructive actions explicit and opt-in
* update documentation when behavior changes

Changes to CI should also stay lightweight and relevant to the repository.

---

## Validation Before Opening a PR

Before opening a pull request, run the checks that apply to your changes.

Examples:

### Fish

```bash
fish -n fish/config.fish
find fish -name '*.fish' -print0 | xargs -0 -n1 fish -n
```

### Shell scripts

```bash
shellcheck scripts/*.sh
bash -n scripts/*.sh
```

### JSON

```bash
jq -e . some-file.json
```

### TOML

Use a TOML-aware parser or formatter if you have one available.

### Niri / KDL

* reload Niri and confirm there are no parse errors
* verify that changed keybinds or layout settings still behave correctly

### GitHub workflow / repository hygiene

If you touch CI or repo support files, make sure the workflow still passes.

---

## Documentation Expectations

If your change affects behavior, layout, requirements, setup flow, or visuals, update the relevant documentation.

That may include:

* `README.md`
* `requirements.md`
* `CONTRIBUTING.md`
* screenshots in `assets/`
* changelog / release notes

Do not leave documentation behind when the repository behavior changes.

---

## Commit Messages

Use clear, descriptive commit messages.

Preferred style:

* conventional type prefix
* optional scope when it helps
* concise subject

Examples:

* `docs(readme): update setup instructions`
* `ci(lint): strengthen workflow validation`
* `refactor(scripts): rename installer to bootstrap`

Signed commits are welcome.

---

## Pull Request Process

1. Create a focused branch.
2. Keep the change scoped and reviewable.
3. Test the affected files or workflow.
4. Update documentation if needed.
5. Open a PR with:

   * what changed
   * why it changed
   * any dependency or behavior impact
   * screenshots, if the visible desktop/app result changed

Small, focused pull requests are strongly preferred over large mixed changes.

---

## Licensing

By contributing, you agree that your contributions will be licensed under the repository license: **AGPL-v3.0**.

See [`LICENSE`](LICENSE) for the full text.

---

## Contact

If you want to propose a larger change first, open an issue.

For direct contact:

* [cuso4ek55@gmail.com](mailto:cuso4ek55@gmail.com)
* [zudin_daniil@mail.ru](mailto:zudin_daniil@mail.ru)
