# Neovim Guide

LazyVim with this repo's config. Leader is `Space`; press it and wait for
which-key. Install and updates: [LINUX_GUIDE.md](LINUX_GUIDE.md).

- [Survive](#survive) - [Move and edit](#move-and-edit) - [Files](#files) -
  [Code](#code) - [Languages](#languages) - [Git](#git) -
  [Debug and test](#debug-and-test) - [AI](#ai) - [Tools](#tools) -
  [Config](#config) - [Troubleshoot](#troubleshoot) - [From VS Code](#from-vs-code)

## Survive

| Mode    | Enter with                         | Leave        |
| ------- | ---------------------------------- | ------------ |
| Normal  | default                            |              |
| Insert  | `i` `a` `o` (`I` `A` `O`)          | `jk` / `Esc` |
| Visual  | `v` char, `V` line, `Ctrl-v` block | `Esc`        |
| Command | `:`                                | `Esc`        |

| Do                           | Keys                            |
| ---------------------------- | ------------------------------- |
| Save / quit / both / discard | `Ctrl-s` / `:q` / `:wq` / `:q!` |
| Quit everything              | `Space Q`                       |
| Undo / redo / repeat edit    | `u` / `Ctrl-r` / `.`            |
| Find file / explorer         | `Space Space` / `Space e`       |
| Every keymap, searchable     | `Space sk`                      |

## Move and edit

| Move                     | Keys                                           |
| ------------------------ | ---------------------------------------------- |
| char / word / WORD       | `h j k l` / `w b e` / `W B` (skip punctuation) |
| line start / text / end  | `0` / `^` / `$`                                |
| to / before char, repeat | `f{c}` `F{c}` / `t{c}` / `;`                   |
| half page (centered)     | `Ctrl-d` / `Ctrl-u`                            |
| file top / bottom / line | `gg` / `G` / `123G`                            |
| paragraph / bracket      | `{` `}` / `%`                                  |
| anywhere on screen       | `s`, type 1-2 chars, then the label (flash)    |

Edits are `[count] verb motion-or-object`:

| Verbs                  | Objects (`i` inner, `a` around)       | Examples                     |
| ---------------------- | ------------------------------------- | ---------------------------- |
| `d` delete, `c` change | `iw` word, `i"` quotes                | `d3w`, `ciw`, `ci"`          |
| `y` yank, `v` select   | `i(` `i{` `i[` brackets, `it` tag     | `da(`, `yi{`, `vip`          |
| `>` `<` indent         | `ip` paragraph, `is` sentence         | `>ip`, `ct;` (up to `;`)     |
| doubled = whole line   | `dd` `cc` `yy` `>>`; `D` `C` = to end | `p` / `P` paste after/before |

Singles: `x` delete char, `r{c}` replace char, `~` toggle case, `J` join
lines, `gcc` / `gc{motion}` comment. Visual selection: `d y c > <`, `u`/`U`
case, `:` runs a command on those lines. Block insert: `Ctrl-v`, `j`/`k`,
`I` or `A`, type, `Esc`. Macro: `qq` record, `q` stop, `@q` replay.

**Search and replace** (`hlsearch` is off; `n`/`N` center the match):

| Keys                         | Does                                               |
| ---------------------------- | -------------------------------------------------- |
| `/pat` `?pat`, `*` `#`       | search fwd / back, word under cursor fwd / back    |
| `:s/a/b/g`, `:%s/a/b/gc`     | line, whole file with confirm (`V` first to limit) |
| `*`, `cgn`, type, `Esc`, `.` | change each next match; `n` skips one              |
| `Space sr` (also visual)     | project-wide replace with preview (grug-far)       |
| `Space cr`                   | LSP rename: use it for identifiers                 |

**Clipboard:** `y`/`p` are the system clipboard, except over SSH, where
LazyVim leaves it off: use `"+y` there, which reaches the local clipboard by
OSC 52 (tmux passes it through). Visual `p` does not overwrite the clipboard.
`Ctrl+Shift+V` pastes in Insert and Command mode. `"0p` pastes the last yank
(deletes skip register `0`); `"ay` / `"ap` use named register `a`.

## Files

| Keys                                | Does                                                  |
| ----------------------------------- | ----------------------------------------------------- |
| `Space Space` / `Space /`           | find file / grep all files                            |
| `Space ,` / `Space fr`              | open buffers / recent files                           |
| `Space sg` `sw` `sd` `st` `sh` `sc` | grep, word, diagnostics, TODOs, help, command history |
| `[b` / `]b`                         | prev / next buffer                                    |
| `Space bd` `bo` `bD`                | close buffer / others / buffer and window             |
| `Space fn`, `gf`                    | new file, open path under cursor                      |
| `Space H`, `Space h`                | harpoon: add file, menu                               |
| `Space 1`-`Space 9`                 | harpoon: jump to file 1-9                             |
| `-`                                 | Oil: parent dir as a buffer, edit names, `:w` applies |

Pickers: type to filter, `Ctrl-j`/`Ctrl-k` move, `Enter` open, `Ctrl-s` /
`Ctrl-v` split / vsplit, `Esc` close.

Explorer (`Space e` root, `Space E` cwd): `l`/`h` open/close, `a` add, `d`
delete, `r` rename, `c` copy, `m` move, `y`/`p` yank/paste, `H` hidden, `I`
ignored, `P` preview, `Backspace` up.

| Windows and terminal              | Keys                            |
| --------------------------------- | ------------------------------- |
| move across splits AND tmux panes | `Ctrl-h/j/k/l`                  |
| split below / right               | `Space -` / `Space \|`          |
| close split, equalize             | `Space wd`, `Ctrl-w =`          |
| floating terminal                 | `Ctrl-\` (`Esc` to Normal mode) |
| terminal (root / cwd)             | `Space ft` / `Space fT`         |

## Code

| Keys                         | Does                                                      |
| ---------------------------- | --------------------------------------------------------- |
| `gd` `gr` `gI` `gy` `gD`     | definition, references, implementation, type, declaration |
| `K`, `gK`, `Ctrl-k` (Insert) | hover, signature help                                     |
| `Space ca` `cr` `cf`         | code action, rename, format                               |
| `Space cd`, `]d` `[d`        | line diagnostics, next / prev                             |
| `]e` `[e`, `]w` `[w`         | next / prev error, warning                                |
| `Space xx` / `xX`            | Trouble: all / this buffer                                |

Completion (blink.cmp): `Ctrl-n`/`Ctrl-p` move, `Enter` accept, `Ctrl-e`
close, `Ctrl-Space` open. Snippets: type the prefix, `Tab`/`Shift-Tab` between
placeholders. Own snippets: JS `cl` (console.log), `asyncfn`; TS `int`
(interface); Python `def` (with docstring); Go `err` (`if err != nil`).

## Languages

Extras in `lazyvim.json` install their own tools through Mason. Formatting
runs on save.

| Language  | LSP                                              | Format                         | Lint              | Debug / test            |
| --------- | ------------------------------------------------ | ------------------------------ | ----------------- | ----------------------- |
| Go        | gopls (gofumpt, staticcheck, hints)              | gofumpt, goimports             | golangci-lint     | delve, neotest-golang   |
| Python    | pyright, ruff                                    | ruff format + organize imports | ruff              | debugpy, neotest-python |
| JS / TS   | vtsls (inlay hints), eslint                      | prettier                       | eslint            | js-debug-adapter        |
| Rust      | rust-analyzer, crates.nvim                       | rustfmt                        | LSP               | codelldb                |
| C / C++   | clangd                                           | clang-format                   | LSP               | codelldb                |
| CMake     | neocmake                                         |                                | cmakelint         |                         |
| Nix       | nil                                              | alejandra                      |                   |                         |
| Shell     |                                                  | shfmt                          | shellcheck        |                         |
| Lua       | lua_ls                                           | stylua                         |                   |                         |
| Docker    | dockerls, compose LSP                            |                                | hadolint          |                         |
| YAML      | yamlls (Actions, kustomize, k8s schemas)         | prettier                       | yamllint          |                         |
| Terraform | terraformls                                      | terraform_fmt                  | tflint            |                         |
| Ansible   | ansiblels                                        |                                | ansible-lint      |                         |
| Markdown  | marksman                                         | prettier                       | markdownlint-cli2 |                         |
| Also      | jsonls, taplo, helm_ls, tailwindcss, html, cssls | prettier                       |                   |                         |

## Git

| Keys                          | Does                                                            |
| ----------------------------- | --------------------------------------------------------------- |
| `Space gg`                    | LazyGit: `Space` stage, `c` commit, `p`/`P` pull/push, `?` help |
| `]h` `[h`                     | next / prev hunk (inline blame is on)                           |
| `Space ghs` `ghr` `ghp` `ghb` | hunk: stage, reset, preview, blame line                         |
| `Space gd`, `gq`              | Diffview: all changes, close                                    |
| `Space gF` / `gH`             | Diffview: file history / branch history                         |
| `Space gB` `gD` `gl`          | Fugitive: blame file, diff split, one-line log                  |

## Debug and test

| Keys                      | Does                                 |
| ------------------------- | ------------------------------------ |
| `Space db` / `dB`         | breakpoint / conditional breakpoint  |
| `Space dc`, `dl`          | continue or start, run last          |
| `Space di` `do` `dO`      | step into, over, out                 |
| `Space du` `de` `dr`      | DAP UI, evaluate (also visual), REPL |
| `Space tr` `tt` `ts` `to` | test: nearest, file, summary, output |

Extra launch configs: Go "Debug test (file)" and "Debug package"; Python
"Launch file (auto venv)" uses `$VIRTUAL_ENV` or `.venv`; JS/TS "Attach to
process".

## AI

Personal machines get Claude Code; work machines (`bootstrap-user.sh --work`)
get Copilot instead, and the Claude plugin is not loaded.

| Claude Code (`claudecode.nvim`) | Keys                             |
| ------------------------------- | -------------------------------- |
| toggle / focus                  | `Space ac` / `Space af`          |
| resume / continue session       | `Space ar` / `Space aC`          |
| add buffer / send selection     | `Space ab` / `Space as` (visual) |
| accept / deny diff              | `Space aa` / `Space ad`          |

Copilot: suggestions appear in the completion menu. Chat: `Space aa` toggle,
`Space aq` quick chat, `Space ap` prompts, `Space ax` clear, `Ctrl-s` submit.

Without nvim: `claude` in a tmux popup ([TMUX_GUIDE.md](TMUX_GUIDE.md)).

## Tools

| Keys / trigger | Does                                                                       |
| -------------- | -------------------------------------------------------------------------- |
| `Space U`      | undo tree                                                                  |
| `Space z`      | zen mode                                                                   |
| `Space mp`     | markdown preview in the browser                                            |
| `Space ut`     | toggle sticky function headers                                             |
| `]t` `[t`      | next / prev TODO, FIXME, HACK                                              |
| `Space D`      | database UI (dadbod): add a `postgres://` URL, run SQL in a scratch buffer |
| automatic      | word highlights, inline hex colors, better quickfix                        |

## Config

```text
~/.config/nvim/
  lazyvim.json            extras (:LazyExtras, x toggles)
  lua/config/options.lua  tabstop 2, no hlsearch, colorcolumn 120, treesitter folds (off)
  lua/config/keymaps.lua  own keymaps
  lua/config/autocmds.lua Python 4 spaces, Go tabs, strip trailing space on save
  lua/plugins/user.lua    theme, plugins, formatters, linters
  lua/plugins/lsp.lua     server settings, extra Mason tools
  lua/plugins/snippets.lua, dap-config.lua, claudecode.lua
```

New keymap (`desc` shows it in which-key):

```lua
vim.keymap.set("n", "<leader>xx", "<cmd>SomeCommand<cr>", { desc = "Description" })
```

Plugin: add `{ "user/repo", opts = {} }` to `plugins/user.lua`, then `:Lazy
sync`; delete the entry and `:Lazy clean` to remove; `enabled = false`
disables a LazyVim default. A plugin with `cmd`, `keys`, `ft` or `event` loads
only when that fires, so it can look missing until used.

## Troubleshoot

| Command        | Shows                                                              |
| -------------- | ------------------------------------------------------------------ |
| `:Lazy`        | plugins: `S` sync, `U` update, `X` clean, `R` restore, `P` profile |
| `:Mason`       | tools: `i` install, `u` update, `U` all, `X` remove                |
| `:LspInfo`     | servers attached to this buffer                                    |
| `:ConformInfo` | formatters for this buffer                                         |
| `:checkhealth` | everything else                                                    |

## From VS Code

| VS Code               | Neovim                           |
| --------------------- | -------------------------------- |
| Ctrl-P / Ctrl-Shift-F | `Space Space` / `Space /`        |
| Ctrl-Tab              | `Space ,` or `[b` `]b`           |
| Ctrl-/                | `gcc`                            |
| Ctrl-D, multi-cursor  | `*` `cgn` `.`, or `Ctrl-v` block |
| Ctrl-. / F2           | `Space ca` / `Space cr`          |
| F12 / Shift-F12       | `gd` / `gr`                      |
| F5 / F8               | `Space dc` / `]d`                |
| Ctrl-backtick         | `Ctrl-\`                         |
| Source control        | `Space gg`                       |
| Extensions / settings | `:Lazy` / [Config](#config)      |
