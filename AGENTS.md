# AGENTS.md

> Single source of truth for every AI agent in this repository (Claude Code,
> Codex, Gemini CLI, Copilot). Read at session start. Follow unconditionally.
> Bullet points only.

## Self-Maintenance

- Edit this file, never `CLAUDE.md`, `GEMINI.md` or
  `.github/copilot-instructions.md`; those import it or hold tool-specific notes.
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
  `install.sh` (symlink configs, back up existing as `.bak`; tool-written
  files get a local stub or merge instead, see Gotchas),
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

- Bias: caution over speed; for trivial tasks, use judgment.
- **Think first:** state assumptions; ask once, upfront, when a requirement is
  unclear. Several interpretations? Present them. Simpler way? Push back.
- **Surgical changes only** - every changed line traces to the request. Mention
  adjacent issues, don't fix them unasked. Remove what your change orphaned;
  leave pre-existing dead code.
- **Simplicity over cleverness.** No speculative abstraction, no handling for
  impossible cases. If 200 lines could be 50, rewrite it.
- **Goal-driven:** turn the task into a checkable goal; multi-step work gets a
  short plan with a check per step (`step -- verify: x`).
- **Done means verified:** run the affected script or `just lint`, read the diff.
  "Should work" is not done. When a fix is runtime state (dconf, systemd,
  resurrect saves), also fix the repo script so it persists across a reinstall.
- Keep docs lean: tables and commands over prose, no fact stated twice. The
  README is a hub; detail lives in `LINUX_GUIDE.md`, `WINDOWS_GUIDE.md`,
  `NVIM_GUIDE.md`, `TMUX_GUIDE.md`.

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
- **Tools write through symlinks into the repo:** `gh`/`glab auth setup-git`
  append to `~/.gitconfig` and Claude Code rewrites `~/.claude/settings.json`.
  Never symlink a file a tool writes to; use a local file that includes or
  merges the tracked one, and check `git diff` for runtime state before committing.

## Decision Log

> Append: `- YYYY-MM-DD: <decision> -- <rationale>`

- 2026-08-28: dropped TopHat for Vitals as the top-bar monitor -- TopHat has no
  GNOME 50 support (upstream issue #204); its meters silently fail to render.
- 2026-09-19: repo goes public with a fresh history (old history stays in a
  private archive) -- work machines may not use personal GitHub, so they pull
  the public repo anonymously; the old history held a former employer's details.
- 2026-09-19: work laptops are thin clients to a remote build server, set up by
  `bootstrap-user.sh --work` -- no sudo there, and Copilot is the approved AI.
- 2026-10-13: `AGENTS.md` is the single source for agent instructions; the
  Claude, Gemini and Copilot files only point to it -- four copies each told
  their agent to append to its own Decision Log, so they were bound to drift.
- 2026-10-13: tool-written files (`~/.gitconfig`, `~/.claude/settings.json`)
  are no longer symlinked; `~/.gitconfig` is a local stub that includes the
  repo file and Claude settings are jq-merged -- a `glab` credential block
  written through the symlink leaked the employer hostname into the public repo.
- 2026-10-13: `CLAUDE.md`/`GEMINI.md` load `AGENTS.md` with an `@` import, and
  the Copilot file holds review notes -- link-only pointers loaded nothing in
  Claude or Gemini; Codex and Copilot read `AGENTS.md` natively.
- 2026-10-13: working discipline follows the four Karpathy principles
  (multica-ai/andrej-karpathy-skills) -- they target the common LLM failures:
  silent assumptions, overengineering, drive-by edits, unverified "done".
- 2026-10-13: aliases cut to what atuin history shows in use (~20 of 251), OMZ
  git plugin dropped -- 13.5k commands since 2024 used almost none of them;
  plumbing (eza `ls`, ssh wrapper, WSL glue, `tdl`, `ccinit`) stays regardless.

## Learned Conventions

> Append when patterns are established.
