# Neovim + LazyVim Guide

Reference for this exact config (LazyVim, leader = `Space`, which-key on `Space`).

## Table of Contents

- [1. Modes and Survival](#1-modes-and-survival)
- [2. Movement](#2-movement)
- [3. Editing](#3-editing)
- [4. The Vim Grammar](#4-the-vim-grammar)
- [5. Visual Mode](#5-visual-mode)
- [6. Clipboard and Registers](#6-clipboard-and-registers)
- [7. Search and Replace](#7-search-and-replace)
- [8. Files, Buffers, Explorers](#8-files-buffers-explorers)
- [9. Telescope](#9-telescope)
- [10. Harpoon](#10-harpoon)
- [11. LSP](#11-lsp)
- [12. Completion and Snippets](#12-completion-and-snippets)
- [13. Git](#13-git)
- [14. Debugging and Testing](#14-debugging-and-testing)
- [15. Terminal](#15-terminal)
- [16. Windows, Splits, Tmux](#16-windows-splits-tmux)
- [17. Plugins (lazy.nvim)](#17-plugins-lazynvim)
- [18. LazyVim Extras](#18-lazyvim-extras)
- [19. Utilities](#19-utilities)
- [20. Mason and Troubleshooting](#20-mason-and-troubleshooting)
- [21. Config Structure and Customizing](#21-config-structure-and-customizing)
- [22. Database (Dadbod)](#22-database-dadbod)
- [23. AI (Claude Code)](#23-ai-claude-code)
- [24. VS Code Habits Translation](#24-vs-code-habits-translation)
- [Quick Reference Card](#quick-reference-card)

## 1. Modes and Survival

| Mode    | Enter with         | Purpose        |
| ------- | ------------------ | -------------- |
| Normal  | `Esc` or `jk`      | navigate, edit |
| Insert  | `i`, `a`, `o`      | type text      |
| Visual  | `v`, `V`, `Ctrl-v` | select text    |
| Command | `:`                | run commands   |

| Task                | Keys              |
| ------------------- | ----------------- |
| Insert text         | `i`               |
| Back to Normal      | `jk` or `Esc`     |
| Save                | `Space w` or `:w` |
| Quit                | `:q`              |
| Save and quit       | `:wq`             |
| Quit without saving | `:q!`             |
| Quit everything     | `Space Q`         |
| Undo / redo         | `u` / `Ctrl-r`    |
| Find file           | `Space Space`     |
| File explorer       | `Space e`         |

Stuck: mash `Esc`, `:q!` force-quits, `:e` reloads a garbled screen.

## 2. Movement

| Key                      | Movement                                     |
| ------------------------ | -------------------------------------------- |
| `h j k l`                | left / down / up / right                     |
| `w` / `b` / `e`          | next word / prev word / end of word          |
| `W` / `B`                | WORD, skips punctuation                      |
| `0` / `^` / `$`          | line start / first non-space / line end      |
| `f{c}` / `t{c}` / `F{c}` | to char / before char / backward to char     |
| `;`                      | repeat last f/t/F/T                          |
| `Ctrl-d` / `Ctrl-u`      | half page down / up (centered)               |
| `gg` / `G`               | top / bottom of file                         |
| `{` / `}`                | prev / next blank line                       |
| `%`                      | matching bracket                             |
| `123G`                   | go to line 123                               |
| `s`                      | flash: type 1-2 chars, then the label letter |

## 3. Editing

**Insert mode entry:**

| Key       | Action                       |
| --------- | ---------------------------- |
| `i` / `a` | insert before / after cursor |
| `I` / `A` | insert at line start / end   |
| `o` / `O` | new line below / above       |
| `s`       | delete char, insert          |

**Delete / change / yank:**

| Key                           | Action                                       |
| ----------------------------- | -------------------------------------------- |
| `x`                           | delete char                                  |
| `dd` / `dw` / `D`             | delete line / to next word / to line end     |
| `cc` / `cw` / `C`             | change line / word / to line end             |
| `ciw` / `ci"` / `ci(` / `ci{` | change inner word / quotes / parens / braces |
| `yy` / `yw` / `y$`            | yank line / word / to line end               |
| `p` / `P`                     | paste after / before                         |

**Misc:**

| Key            | Action               |
| -------------- | -------------------- |
| `u` / `Ctrl-r` | undo / redo          |
| `.`            | repeat last edit     |
| `r{c}`         | replace one char     |
| `~`            | toggle case          |
| `J`            | join with line below |
| `>>` / `<<`    | indent right / left  |

## 4. The Vim Grammar

Pattern: `[count] + verb + motion/object`.

| Verbs     |              | Motions    |                   | Text objects   |                        |
| --------- | ------------ | ---------- | ----------------- | -------------- | ---------------------- |
| `d`       | delete (cut) | `w` / `b`  | next / prev word  | `iw` / `aw`    | inner / a word         |
| `c`       | change       | `0` / `$`  | line start / end  | `i"` / `a"`    | inside / around quotes |
| `y`       | yank (copy)  | `}`        | next paragraph    | `i(` `i{` `i[` | inside brackets        |
| `v`       | select       | `gg` / `G` | file top / bottom | `it`           | inside HTML tag        |
| `>` / `<` | indent       | `%`        | matching bracket  | `ip` / `is`    | paragraph / sentence   |

| Command | Result                     |
| ------- | -------------------------- |
| `d3w`   | delete next 3 words        |
| `ciw`   | replace word under cursor  |
| `ci"`   | replace text inside quotes |
| `da(`   | delete parens and contents |
| `yi{`   | copy inside braces         |
| `>ip`   | indent paragraph           |
| `ct;`   | change up to `;`           |
| `vip`   | select paragraph           |

## 5. Visual Mode

**Start a selection:**

| Key                  | Selection           |
| -------------------- | ------------------- |
| `v` / `V` / `Ctrl-v` | char / line / block |

**On a selection:**

| Key             | Action                       |
| --------------- | ---------------------------- |
| `d` / `y` / `c` | delete / yank / change       |
| `>` / `<`       | indent right / left          |
| `u` / `U`       | lowercase / uppercase        |
| `:`             | run a command on those lines |

Block edit (multi-cursor): `Ctrl-v`, extend with `j`/`k`, `I` or `A`, type, `Esc`.

## 6. Clipboard and Registers

LazyVim sets `clipboard = "unnamedplus"`: yank and paste are the system
clipboard. `Ctrl+Shift+C/V` are Ghostty bindings, not nvim's; visual `p` is
remapped to `"_dP` so it does not clobber the clipboard.

**Clipboard:**

| Scenario                     | How                                    |
| ---------------------------- | -------------------------------------- |
| Copy in nvim                 | `y` (or `yy`, `yiw`, `yi"`)            |
| Paste in nvim                | `p` / `P`                              |
| nvim to other app            | `y`, then `Ctrl+Shift+V` in the app    |
| Other app to nvim            | `Ctrl+Shift+C` in the app, then `p`    |
| Paste in Insert/Command mode | `Ctrl+Shift+V` (mapped in keymaps.lua) |

**Registers:**

| Register  | Contents                                     |
| --------- | -------------------------------------------- |
| `"`       | default (used by `y` and `d`)                |
| `+`       | system clipboard (synced)                    |
| `0`       | last yank (deletes skip it); `"0p` pastes it |
| `"a`-`"z` | named slots: `"ay` to yank, `"ap` to paste   |

## 7. Search and Replace

| Key             | Action                              |
| --------------- | ----------------------------------- |
| `/pat` / `?pat` | search forward / backward           |
| `n` / `N`       | next / prev match (centered)        |
| `*` / `#`       | search word under cursor fwd / back |
| `Space /`       | live grep all files                 |
| `Space s`+...   | more search pickers                 |

`hlsearch = false`; select with `V` first to limit `:s` to those lines.

| Key                 | Replace                                               |
| ------------------- | ----------------------------------------------------- |
| `:s/old/new/g`      | current line                                          |
| `:%s/old/new/g`     | whole file (add `c` to confirm each)                  |
| `Space sr`          | grug-far project-wide find and replace (live preview) |
| `Space sr` (visual) | grug-far with selection                               |
| `Space cr`          | LSP rename - prefer for identifiers                   |

## 8. Files, Buffers, Explorers

| Key                     | Action                      |
| ----------------------- | --------------------------- |
| `Space ,`               | list open buffers           |
| `Space Space`           | fuzzy find file             |
| `[b` / `]b`             | prev / next buffer          |
| `Space bd` / `Space bD` | close buffer / close others |
| `Space fn`              | new file                    |
| `Space fr`              | recent files                |
| `gf`                    | open file path under cursor |

**Neo-tree sidebar (`Space e`):**

| Key             | Action                         |
| --------------- | ------------------------------ |
| `Enter`         | open / expand                  |
| `a` / `d` / `r` | create / delete / rename       |
| `c` / `m`       | copy / move                    |
| `y` / `Y`       | copy filename / relative path  |
| `H` / `/` / `q` | toggle hidden / filter / close |

Oil (`-`): parent dir as an editable buffer. Edit names to rename, `dd` to
delete, add a line to create, `:w` to apply.

## 9. Telescope

| Key           | Searches          |
| ------------- | ----------------- |
| `Space Space` | files by name     |
| `Space /`     | text in all files |
| `Space ,`     | open buffers      |
| `Space fr`    | recent files      |
| `Space sg`    | grep string       |
| `Space sw`    | word under cursor |
| `Space sd`    | diagnostics       |
| `Space sk`    | keymaps           |
| `Space sh`    | help tags         |
| `Space sc`    | command history   |
| `Space st`    | TODOs             |

Inside a picker: type to filter, `Ctrl-j`/`Ctrl-k` move, `Enter` open,
`Ctrl-x`/`Ctrl-v` open in split, `Esc` close.

## 10. Harpoon

| Key                 | Action                  |
| ------------------- | ----------------------- |
| `Space ha`          | add current file        |
| `Space hh`          | menu (reorder / remove) |
| `Space 1`-`Space 5` | jump to file 1-5        |

## 11. LSP

**Navigation:**

| Key               | Action           |
| ----------------- | ---------------- |
| `gd`              | go to definition |
| `gr`              | references       |
| `gI`              | implementation   |
| `gy`              | type definition  |
| `gD`              | declaration      |
| `K`               | hover docs       |
| `gK`              | signature help   |
| `Ctrl-k` (Insert) | signature help   |

**Actions and diagnostics:**

| Key                     | Action                     |
| ----------------------- | -------------------------- |
| `Space ca`              | code actions (quick fixes) |
| `Space cr`              | rename symbol              |
| `Space cf`              | format file                |
| `Space cd`              | line diagnostics           |
| `]d` / `[d`             | next / prev diagnostic     |
| `]e` / `[e`             | next / prev error          |
| `]w` / `[w`             | next / prev warning        |
| `Space xx` / `Space xX` | Trouble list / buffer only |

**Format on save (conform.nvim):**

| Language                    | Formatter                          |
| --------------------------- | ---------------------------------- |
| Go                          | gofumpt, goimports                 |
| Python                      | ruff_format, ruff_organize_imports |
| JS/TS/JSON/YAML/MD/HTML/CSS | prettier                           |
| Lua                         | stylua                             |
| Shell                       | shfmt                              |
| Terraform                   | terraform_fmt                      |
| Rust                        | rustfmt                            |

**Lint on save (nvim-lint):**

| Language   | Linter        |
| ---------- | ------------- |
| Go         | golangci-lint |
| Python     | ruff          |
| JS/TS      | eslint_d      |
| Shell      | shellcheck    |
| Dockerfile | hadolint      |
| YAML       | yamllint      |
| Terraform  | tflint        |
| Ansible    | ansible-lint  |

## 12. Completion and Snippets

| Key                 | Action                 |
| ------------------- | ---------------------- |
| `Ctrl-n` / `Ctrl-p` | next / prev suggestion |
| `Enter` or `Tab`    | accept                 |
| `Ctrl-e`            | close menu             |
| `Ctrl-Space`        | trigger manually       |

Sources: LSP, snippets, buffer words, paths. LuaSnip + friendly-snippets: type
the prefix, then `Tab`/`Shift-Tab` between placeholders.

| Language   | Prefix    | Expands to                       |
| ---------- | --------- | -------------------------------- |
| JS         | `cl`      | `console.log();`                 |
| JS         | `asyncfn` | async function template          |
| TypeScript | `int`     | interface template               |
| Python     | `def`     | function with docstring          |
| Go         | `err`     | `if err != nil { return }` block |

## 13. Git

**LazyGit (`Space gg`):**

| Key             | Action                         |
| --------------- | ------------------------------ |
| `1`-`5`         | switch panels                  |
| `Space` / `a`   | stage/unstage file / stage all |
| `c` / `p` / `P` | commit / pull / push           |
| `Enter`         | view diff / expand             |
| `d`             | discard changes                |
| `b`             | branch actions                 |
| `?` / `q`       | help / quit                    |

**Gitsigns (inline blame is on):**

| Key                       | Action             |
| ------------------------- | ------------------ |
| `]h` / `[h`               | next / prev hunk   |
| `Space ghs` / `Space ghr` | stage / reset hunk |
| `Space ghp`               | preview hunk       |
| `Space ghb`               | blame line (full)  |

**Diffview:**

| Key                     | Action                        |
| ----------------------- | ----------------------------- |
| `Space gd`              | open diffview (all changes)   |
| `Space gh` / `Space gH` | file history / branch history |
| `Space gq`              | close                         |

**Fugitive:**

| Key        | Action                    |
| ---------- | ------------------------- |
| `Space gB` | blame full file           |
| `Space gD` | side-by-side diff of file |
| `Space gl` | one-line git log          |

Fugitive commands: `:Git blame`, `:Git log`, `:Gvdiffsplit`, `:Gread`, `:Gwrite`.

## 14. Debugging and Testing

Adapters: delve (Go), debugpy (Python), js-debug-adapter (JS/TS); the DAP UI
opens and closes with the session.

| Key        | Action                      |
| ---------- | --------------------------- |
| `Space db` | toggle breakpoint           |
| `Space dB` | conditional breakpoint      |
| `Space dc` | continue / start            |
| `Space di` | step into                   |
| `Space do` | step over                   |
| `Space dO` | step out                    |
| `Space du` | toggle DAP UI               |
| `Space de` | evaluate (normal or visual) |
| `Space dr` | open REPL                   |
| `Space dl` | run last config             |

**Extra debug configs:**

| Language | Config                    | Purpose                       |
| -------- | ------------------------- | ----------------------------- |
| Go       | "Debug test (file)"       | debug current test file       |
| Go       | "Debug package"           | debug current package         |
| Python   | "Launch file (auto venv)" | detects .venv or $VIRTUAL_ENV |
| JS/TS    | "Attach to process"       | attach to running Node        |

**Testing (neotest):**

| Key        | Action                |
| ---------- | --------------------- |
| `Space tt` | run nearest test      |
| `Space tf` | run all tests in file |
| `Space ts` | toggle summary panel  |
| `Space to` | toggle output panel   |

## 15. Terminal

| Key                     | Action                                |
| ----------------------- | ------------------------------------- |
| `Ctrl-\`                | toggle floating terminal (ToggleTerm) |
| `Esc`                   | exit terminal mode to Normal          |
| `Space ft` / `Space fT` | LazyVim terminal (root dir / cwd)     |

## 16. Windows, Splits, Tmux

| Key                    | Action                                                  |
| ---------------------- | ------------------------------------------------------- |
| `Ctrl-h/j/k/l`         | move between splits AND tmux panes (vim-tmux-navigator) |
| `Space -` / `Space \|` | horizontal / vertical split                             |
| `Space wd`             | close current split                                     |
| `Ctrl-w =`             | equalize splits                                         |

## 17. Plugins (lazy.nvim)

**`:Lazy` manager:**

| Key       | Action                      |
| --------- | --------------------------- |
| `S`       | sync (install + update)     |
| `U` / `I` | update / install missing    |
| `X`       | clean unused                |
| `C`       | check for updates           |
| `L` / `P` | logs / profile (load times) |
| `R`       | restore after a bad update  |
| `q`       | close                       |

Add a plugin: `{ "username/plugin-name", opts = {} }` in `plugins/user.lua`,
then `:Lazy sync`. Remove: delete the entry, `:Lazy clean`. Disable a LazyVim
default: `{ "some/plugin", enabled = false }` (done here for auto-session).

**Lazy-loading triggers (why a plugin seems missing until used):**

| Trigger                 | Loads           | Examples here                                   |
| ----------------------- | --------------- | ----------------------------------------------- |
| `lazy = false`          | at startup      | catppuccin, vim-tmux-navigator                  |
| `event = "BufReadPost"` | on file open    | gitsigns, illuminate, colorizer, todo-comments  |
| `event = "InsertEnter"` | entering Insert | better-escape                                   |
| `ft = ...`              | per filetype    | markdown-preview, nvim-bqf (qf)                 |
| `cmd = ...`             | on command      | LazyGit, Oil, Diffview, DBUI, Fugitive, ZenMode |
| `keys = ...`            | on keypress     | undotree, grug-far, DAP, neotest, Claude Code   |

## 18. LazyVim Extras

`:LazyExtras` lists extras; `x` toggles one. Saved to `lazyvim.json`.

| Extra                 | Provides                                     |
| --------------------- | -------------------------------------------- |
| `lang.go`             | gopls, gofumpt, goimports, delve, neotest-go |
| `lang.python`         | basedpyright, debugpy, neotest-python        |
| `lang.typescript`     | vtsls, prettier, js-debug-adapter            |
| `lang.rust`           | rust-analyzer, rustfmt, crates.nvim          |
| `lang.docker`         | Dockerfile LSP, compose LSP                  |
| `lang.terraform`      | terraform-ls, tflint                         |
| `lang.helm`           | Helm templates                               |
| `lang.yaml`           | yamlls with schemas                          |
| `lang.json`           | jsonls with schemas                          |
| `lang.markdown`       | markdown LSP, preview                        |
| `lang.tailwind`       | Tailwind IntelliSense                        |
| `lang.ansible`        | ansible-language-server                      |
| `lang.toml`           | taplo                                        |
| `formatting.prettier` | prettier                                     |
| `linting.eslint`      | eslint_d                                     |
| `test.core`           | neotest framework                            |
| `dap.core`            | DAP framework + UI                           |
| `editor.harpoon2`     | Harpoon v2                                   |
| `coding.luasnip`      | LuaSnip snippet engine                       |

## 19. Utilities

| Plugin             | What it does                     | Use                     |
| ------------------ | -------------------------------- | ----------------------- |
| mini.surround      | add/delete/change surroundings   | `gsa"`, `gsd"`, `gsr"'` |
| undotree           | visual undo history              | `Space U`               |
| zen-mode           | distraction-free view            | `Space z`               |
| markdown-preview   | live browser preview (.md)       | `Space mp`              |
| treesitter-context | sticky function headers          | `Space ut` toggle       |
| todo-comments      | highlight/search TODO/FIXME/HACK | `Space st`, `]t`/`[t`   |
| vim-illuminate     | highlight word occurrences       | automatic               |
| nvim-colorizer     | inline hex colors                | automatic               |
| nvim-bqf           | better quickfix windows          | automatic               |

## 20. Mason and Troubleshooting

**`:Mason` UI:**

| Key             | Action                       |
| --------------- | ---------------------------- |
| `i` / `u` / `X` | install / update / uninstall |
| `U`             | update all                   |
| `1`-`5`         | filter by category           |
| `g?`            | help                         |
| `q`             | close                        |

**Diagnose:**

| Command        | Shows                              |
| -------------- | ---------------------------------- |
| `:LspInfo`     | servers attached to this buffer    |
| `:Mason`       | installed / missing tools          |
| `:checkhealth` | general health check               |
| `:Lazy`        | plugin status (green dot = loaded) |
| `:ConformInfo` | formatters for this buffer         |
| `Space sk`     | searchable list of every keymap    |
| `:help {kw}`   | docs for a keyword                 |

Auto-installed via `ensure_installed`: prettier, ruff, black, isort, gofumpt,
goimports, stylua, shfmt, eslint_d, golangci-lint, shellcheck, hadolint,
yamllint, ansible-lint, tflint, debugpy, delve, js-debug-adapter.

## 21. Config Structure and Customizing

```text
~/.config/nvim/
  init.lua            -- entry point: loads config.lazy
  lazyvim.json        -- LazyVim extras (:LazyExtras)
  stylua.toml         -- Lua formatter config
  lua/config/
    lazy.lua          -- lazy.nvim bootstrap
    options.lua       -- vim options
    keymaps.lua       -- custom key mappings
    autocmds.lua      -- autocmds (filetype settings, save hooks)
  lua/plugins/
    user.lua          -- theme, nav, git, format, lint, tools, UI
    lsp.lua           -- LSP server settings + Mason ensure_installed
    snippets.lua      -- custom LuaSnip snippets
    dap-config.lua    -- extra debug configurations
    claudecode.lua    -- Claude Code integration
```

| I want to...           | Edit                              |
| ---------------------- | --------------------------------- |
| add/change keybindings | `config/keymaps.lua`              |
| change editor options  | `config/options.lua`              |
| add/remove plugins     | `plugins/user.lua`                |
| configure LSP servers  | `plugins/lsp.lua`                 |
| add snippets           | `plugins/snippets.lua`            |
| add debug configs      | `plugins/dap-config.lua`          |
| toggle language extras | `:LazyExtras`                     |
| disable a plugin       | `enabled = false` in plugin files |

Keybinding pattern; `desc` makes it show in which-key:

```lua
vim.keymap.set("n", "<leader>xx", "<cmd>SomeCommand<cr>", { desc = "Description" })
```

`options.lua`: `tabstop = 2`, `hlsearch = false`, `colorcolumn = "120"`,
treesitter folds, undodir at `~/.vim/undodir`. `autocmds.lua`: Python 4-space,
Go tabs, trailing whitespace stripped on write.

## 22. Database (Dadbod)

| Key       | Action       |
| --------- | ------------ |
| `Space D` | toggle DB UI |

In the UI: add a connection string (`postgres://user:pass@host/db`), browse
tables, run SQL in a scratch buffer with the keymap shown.

## 23. AI (Claude Code)

`coder/claudecode.nvim` speaks the same protocol as the VS Code extension: diffs
preview in nvim, selections flow to Claude. No inline completion plugin.

| Key                 | Action                   |
| ------------------- | ------------------------ |
| `Space ac`          | toggle Claude terminal   |
| `Space af`          | focus Claude             |
| `Space ar`          | resume session           |
| `Space aC`          | continue session         |
| `Space ab`          | add current buffer       |
| `Space as` (visual) | send selection to Claude |
| `Space aa`          | accept diff              |
| `Space ad`          | deny diff                |

Alternative: `claude` in a tmux pane (`prefix + a` popup) works without nvim.

## 24. VS Code Habits Translation

| VS Code                   | Neovim                           |
| ------------------------- | -------------------------------- |
| Ctrl-P (find file)        | `Space Space`                    |
| Ctrl-Shift-F (search all) | `Space /`                        |
| Ctrl-Tab (switch file)    | `Space ,` or `[b`/`]b`           |
| Ctrl-S (save)             | `Space w`                        |
| Ctrl-Z / Ctrl-Shift-Z     | `u` / `Ctrl-r`                   |
| Ctrl-C / Ctrl-V           | `y` / `p` (system clipboard)     |
| Ctrl-/ (comment)          | `gcc` (line), `gc` + motion      |
| Ctrl-D (select next)      | `*` then `cgn` then `.`          |
| Ctrl-. (quick fix)        | `Space ca`                       |
| F2 (rename)               | `Space cr`                       |
| F12 / Shift-F12           | `gd` / `gr`                      |
| F5 (debug)                | `Space dc`                       |
| F8 (next error)           | `]d`                             |
| Ctrl-backtick (terminal)  | `Ctrl-\`                         |
| Explorer sidebar          | `Space e`                        |
| Extensions panel          | `:Lazy`                          |
| Settings                  | edit lua files (sec. 21)         |
| Multi-cursor              | `Ctrl-v` block, or `*`+`cgn`+`.` |
| Source control panel      | `Space gg` (LazyGit)             |

Multi-cursor (`cgn`): `/word` Enter, `cgn`, type the replacement, `Esc`, then `.`
for the next match or `n` to skip. Macros: `qq` record, `q` stop, `@q` replay.

## Quick Reference Card

```text
MOVEMENT            EDITING             FILES
h j k l   arrows    i    insert         Space Space  find file
w b e     words     a    append         Space /      grep files
0 $       line      o/O  new line       Space ,      buffers
gg G      file      dd   delete line    Space e      explorer
Ctrl-d/u  scroll    yy   yank line      Space fr     recent
s         flash     p    paste          Space 1-5    harpoon
{ }       para      ciw  change word    gd           go to def
%         bracket   u    undo           gr           references
f{c}      find      .    repeat edit    K            hover docs

CLIPBOARD           GIT                 TOOLS
y    yank=copy      Space gg  lazygit   :Lazy       plugins
p    paste          Space gd  diffview  :Mason      lsp/tools
yy   copy line      ]h / [h   hunks     :LazyExtras extras
"0p  paste yank     Space ghs stage     :checkhealth diagnose
                    Space gB  blame     Ctrl-\      terminal

SAVE/QUIT           SEARCH              AI / DEBUG
Space w   save      /pattern  search    Space ac  claude
:q        quit      Space /   grep all  Space db  breakpoint
:wq       save+q    Space sr  replace   Space dc  start/cont
Space Q   quit all  Space st  TODOs     Space tt  run test
```
