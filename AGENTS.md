# AGENTS.md

> Project instructions for Codex in this repository.
> Read at session start. Follow unconditionally. Bullet points only.

## Self-Maintenance

- Populate **Project Context** when you discover structure, conventions, or tooling.
- Append to **Decision Log** when a significant decision is made.
- Append to **Learned Conventions** when a pattern is established.
- Never remove or weaken rules without explicit approval.

## Project Context

- **What it is:** personal dotfiles - configs, install scripts, and helper
  scripts symlinked into `$HOME`. Not an application.
- **Languages:** Bash (most scripts), Lua (Neovim config), some Nix, TOML/YAML config.
- **Runtimes:** never `apt install` a language toolchain; they come from Nix dev
  shells or mise. Ubuntu owns the desktop, Nix owns runtimes, Docker owns services.
- **Key commands:** `just install` (symlink configs) | `just system` (GNOME/desktop)
  | `just update` (update everything) | `just lint` | `just fmt`.
- **Entry scripts:** `bootstrap.sh` (install every tool, idempotent),
  `install.sh` (symlink configs, back up existing as `.bak`),
  `setup-system.sh` (font, Ghostty, GNOME keys, extensions, systemd),
  `bootstrap-user.sh` (no-sudo install into `$HOME`; `--work` = Copilot, no Claude).
- **Public repo:** anyone can read it. Hostnames, employer names, work emails,
  and secrets go in untracked files (`~/.ssh/config.local`, `~/.gitconfig.local`,
  `~/.secrets.env`, `~/.zshrc.local`), never in the tree.
- **Work profile:** marker `~/.config/dotfiles/work`, read via `is_work` in
  `hw-profile.sh` (Lua: `vim.g.dotfiles_work`). Gate work-vs-personal on that.
- **Detection:** `bin/hw-profile.sh` gates everything hardware/session-specific
  (laptop/desktop/WSL, GPU vendor, Wayland/X11, serial). Source it; don't
  duplicate its checks.
- **Environment:** Ubuntu, GNOME on Wayland, hybrid Intel+AMD+NVIDIA laptop,
  Ghostty + zsh + Starship + tmux + Neovim, Catppuccin Mocha everywhere.

## Conventions (this repo)

- **Shell:** `set -euo pipefail`, shellcheck-clean, formatted with shfmt. Quote
  expansions. Every script must be idempotent - safe to rerun after a failure.
- **Formatters:** shfmt (shell), stylua (Lua), alejandra (Nix), markdownlint (md).
  Run `just lint` and `just fmt` before declaring done.
- **Plain ASCII only** in code and docs: no em dashes, unicode arrows, or emoji.
- **Prefer editing existing config** over adding new tools or files.
- **Do not hardcode** the ghostty/terminal path or a package's install method;
  detect it (apt vs snap, GPU vendor, session type) at runtime.

## Git

- Conventional Commits: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`.
- **Never** add `Co-Authored-By` or any AI attribution to commits or PRs.
- One logical change per commit. Never commit secrets or `~/.secrets.env` content.
- The user commits and pushes themselves unless they ask otherwise.

## Working Discipline

- State assumptions; ask once, upfront, when a requirement is unclear.
- Surgical changes only - every changed line traces to the request. Mention
  adjacent issues, don't fix them unasked.
- Simplicity over cleverness. No speculative abstraction.
- **Done means verified:** run the affected script or `just lint`, read the diff.
  "Should work" is not done. When a fix is runtime state (dconf, systemd,
  resurrect saves), also fix the repo script so it persists across a reinstall.
- Keep docs lean. The README is deliberately terse; detailed guides live in
  their own files (`NVIM_GUIDE.md`, `TMUX_GUIDE.md`).

## Gotchas

- **GNOME keybindings:** clearing a built-in media key needs `gsettings set`, not
  `dconf write` - dconf writes did not reach the layer GNOME reads. Custom
  keybindings via `dconf write .../custom-keybindings/*` do work.
- **Ghostty wrapper:** `/usr/local/bin/ghostty` must exec the real binary
  (`/usr/bin/ghostty` for apt, `/snap/bin/ghostty` for snap). Detect it; a
  hardcoded snap path silently breaks every ghostty keybinding.
- **README tables** are kept in markdownlint "aligned" style. A naive
  pipe-splitter corrupts cells containing an escaped `\|` - split on unescaped
  pipes only when reformatting.
- **`grep -q` on a pipe under `set -o pipefail`:** grep exits on first match and
  the upstream command dies with SIGPIPE (141), which pipefail surfaces as
  failure - a false negative. Grep a captured variable/here-string instead
  (this silently made `apt_available` skip every gaming package).

## Decision Log

> Append: `- YYYY-MM-DD: <decision> -- <rationale>`

- 2026-08-28: dropped TopHat for Vitals as the top-bar monitor -- TopHat has no
  GNOME 50 support (upstream issue #204); its meters silently fail to render.
- 2026-09-19: repo goes public with a fresh history (old history stays in a
  private archive) -- work machines may not use personal GitHub, so they pull
  the public repo anonymously; the old history held a former employer's details.
- 2026-09-19: work laptops are thin clients to a remote build server, set up by
  `bootstrap-user.sh --work` -- no sudo there, and Copilot is the approved AI.

## Learned Conventions

> Append when patterns are established.
