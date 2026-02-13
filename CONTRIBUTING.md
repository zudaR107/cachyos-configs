# Contributing to cachyos-configs

Thanks for considering a contribution. This repository is intentionally small and portable: it tracks only the minimal set of configuration files that are worth versioning for a CachyOS-based desktop.

## Goals

Contributions should:

* Keep configs **portable** and **safe to publish**
* Avoid machine-specific state and auto-generated noise
* Be easy to understand and maintain

## What We Accept

* Improvements to existing tracked configs (readability, structure, comments)
* Small, clearly useful additions that fit the “minimal configs” idea
* Documentation improvements (README, guides, requirements, troubleshooting)
* Simple automation (install script, lint checks) that does not add heavy dependencies

## What We Do Not Accept

* Secrets or sensitive data (tokens, cookies, sync data, private URLs, SSH keys)
* Machine-specific identifiers (device IDs, profile IDs, telemetry IDs)
* Frequently changing state (MRU lists, caches, history files, window geometry, timestamps)
* Large theme packs / binaries / vendor bundles
* Files that are primarily GUI-generated unless they are stable and reviewed

## Repository Structure

* Configs are stored in a **portable layout** mirroring `~/.config/<app>/...`.
* Keep new additions grouped by application (a top-level folder per app).
* Prefer splitting large configs into smaller files if the target tool supports includes.

## Style Guidelines

### Comments and documentation

* Write comments in **English**.
* Keep comments **dry and documentation-like**.
* Use comments to explain **intent** (why) rather than repeating syntax (what).
* Always add a `Location:` comment near the top of each config.

### Formatting

* Use **LF** line endings.
* Avoid trailing whitespace.
* Prefer consistent indentation as used by the file format:

  * `*.fish`: Fish conventions
  * `*.toml`: standard TOML
  * `*.kdl`: consistent indentation
  * `*.json` / `*.jsonc`: stable ordering and readable spacing

### Portability rules

* Do not hardcode absolute paths outside of `$HOME` unless required.
* Avoid distro-/host-specific environment variables unless necessary.
* Do not include personal data (usernames, emails) unless required by upstream config format.

## Testing / Validation

Before opening a PR, verify that changes are syntactically valid and do not break the target tool.

Recommended checks (run what applies):

* Fish:

  * `fish -n ~/.config/fish/config.fish`
  * `fish_indent --check` (if available)
* TOML:

  * `taplo fmt --check` (if you use Taplo)
* JSON:

  * `jq -e . <file>` (for strict JSON)
  * For JSONC, validate manually or with an editor extension.
* Niri KDL:

  * Restart Niri / reload config and confirm no parse errors.

If you add scripts or CI, keep them minimal and documented.

## Commit Messages

* Use clear, descriptive commit messages.
* Conventional commits (e.g. `feat: ...`, `fix: ...`, `docs: ...`).
* Sign commits (SSH/GPG).

## Pull Request Process

1. Fork the repo and create a branch:

   * `git checkout -b feat/<short-topic>` or `fix/<short-topic>`
2. Make changes and test locally.
3. Update documentation if behavior changes.
4. Open a PR with:

   * What changed
   * Why it changed
   * Any dependencies introduced
   * Screenshots (optional) if UI changes are visible

## Licensing

By contributing, you agree that your contributions will be licensed under the repository license: **AGPL-v3.0**.

## Contact

If you have questions or want to propose larger changes first, open an issue or contact:

* Email: **[cuso4ek55@gmail.com](mailto:cuso4ek55@gmail.com)**
* Email: **[zudin_daniil@mail.ru](mailto:zudin_daniil@mail.ru)**
