# tmux Guide

Reference for this exact config (prefix = `Ctrl-a`). Everything is a chord:
press `Ctrl-a`, release, then the next key.

## The mental model

- **Session** - a whole workspace that survives closing the terminal. One per project.
- **Window** - a tab inside a session.
- **Pane** - a split inside a window.

## Start, detach, attach

```bash
tmux                 # start a session
tmux new -s myproj   # start a named session
tmux ls              # list sessions
tmux a               # attach to the last session
tmux a -t myproj     # attach to a named one
```

- `Ctrl-a` then `d` - **detach**. The session keeps running in the background;
  reattach later with `tmux a`. This is the whole point of tmux.
- Type `exit` in the last pane to close it for good.

## Daily bindings (all after `Ctrl-a`)

| Key                   | Action                                     |
| --------------------- | ------------------------------------------ |
| `\|` / `-`            | Split left-right / top-bottom              |
| `h j k l`             | Move between panes                         |
| `H J K L`             | Resize panes                               |
| `z`                   | Zoom a pane fullscreen (again to unzoom)   |
| `x`                   | Kill the current pane                      |
| `c`                   | New window (tab)                           |
| `Ctrl-h` / `Ctrl-l`   | Previous / next window                     |
| `Tab`                 | Last used window                           |
| `f`                   | Fuzzy session picker                       |
| `p`                   | Project sessionizer (zoxide)               |
| `a`                   | Claude Code popup                          |
| `g` / `B` / `K` / `N` | lazygit / btop / k9s / nvim popup          |
| `r`                   | Reload config                              |
| `?`                   | List every binding (`q` to close)          |

## Copy text from the scrollback

1. `Ctrl-a` then `[` enters copy mode.
2. Move with `h j k l` or arrows; page with `Ctrl-u` / `Ctrl-d`.
3. `v` starts selecting, `y` yanks it to the clipboard, `q` exits.

Or press `Ctrl-a` then `F` for "thumbs": every URL, hash, and path on screen
gets a letter label - type it to copy that item instantly.

## Plugins (TPM)

Plugins are listed in `tmux.conf`. Manage them with (after `Ctrl-a`):

- `I` - install any newly added plugins
- `U` - update installed plugins
- `Alt-u` - uninstall plugins removed from the config

Sessions auto-save every 15 minutes (resurrect + continuum) and restore on the
next start, so a reboot does not lose your layout.

## A typical flow

```text
Ctrl-a p        # jump to a project, creating or attaching its session
Ctrl-a -        # split a shell below
Ctrl-a g        # pop open lazygit, commit, close it
Ctrl-a d        # detach and walk away; work keeps running
```
