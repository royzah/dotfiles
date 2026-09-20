# Global instructions

## Who I am

Full-stack + DevOps + embedded developer. Daily stack: Nix flakes +
direnv per project, Docker for services, Go / Rust / Python / TypeScript,
Kubernetes, embedded Linux (ARM SoCs, serial debugging).

## Environment

- Ubuntu, zsh + starship, Ghostty, tmux, Neovim (LazyVim), Catppuccin Mocha everywhere
- Runtimes come from Nix dev shells or mise - never suggest `apt install`
  for language toolchains
- Dotfiles live in `~/Code/dotfiles` (symlinked by its `install.sh`)

## How I like to work

- Conventional commits (`feat:`, `fix:`, `chore:` ...)
- Never add `Co-Authored-By` or any AI attribution to commits or PRs
- Plain ASCII in code and docs: no em dashes, arrows, emoji
- Prefer editing existing config over adding new tools
- Keep shell scripts `set -euo pipefail`, shellcheck-clean
- Format Nix with alejandra, Lua with stylua, shell with shfmt

## Code comments

- Before committing, read the diff and check the comments first
- Only if essential, and only the why: not the what, not how it was found
- One line where possible. Needing a paragraph means the code is unclear

## Reviewing PRs

- Always post as pending, never submit
- Inline on the line it is about, not a wall of text in the body
- Short, casual, friendly
- Assertive when certain, a question when not
