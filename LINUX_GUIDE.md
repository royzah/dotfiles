# Linux Guide

Ubuntu desktop or laptop, plus no-sudo servers. Every script is idempotent:
rerun any of them safely. Windows? See [WINDOWS_GUIDE.md](WINDOWS_GUIDE.md).

- [Install](#install) - [Daily use](#daily-use) - [AI agents](#ai-agents) -
  [Shortcuts](#shortcuts) - [Commands](#commands) - [Hardware](#hardware) -
  [Extras](#extras) - [Maintenance](#maintenance)

## Install

Ubuntu 26.04 LTS (24.04 works; 22.04 needs [tree-sitter](#ubuntu-2204)).

### 1. SSH key

Commits are signed with it, so restore it or create it first:

```bash
ssh-keygen -t ed25519 -C "royzah@gmail.com" -f ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub    # github.com/settings/keys: add as auth AND signing key
```

### 2. Bootstrap

```bash
git clone https://github.com/royzah/dotfiles.git ~/Code/dotfiles && cd ~/Code/dotfiles
./bootstrap.sh    # apt base, zsh, Nix, Docker, brew CLI tools, mise runtimes, Claude Code
```

Log out and back in: default shell, `docker` and `dialout` groups.

### 3. Link and configure

```bash
./install.sh         # link configs, back up what was there as .bak
./setup-system.sh    # font, Ghostty, GNOME keys + extensions, web apps, systemd units
git remote set-url origin git@github.com:royzah/dotfiles.git
```

| File written by tools     | Handled as                                    |
| ------------------------- | --------------------------------------------- |
| `~/.gitconfig`            | local file that includes the repo `gitconfig` |
| `~/.claude/settings.json` | merged: repo keys win, local keys survive     |
| everything else           | symlink into the repo                         |

### 4. Hardware

```bash
just hw       # what was detected; changes nothing
just gpu      # driver, Vulkan, VA-API per GPU vendor (PRIME offload on hybrids)
just tune     # zram, journald cap, writeback, cgroups, pstate + EPP
sudo reboot
```

### 5. Sign in

```bash
claude        # /login, then trust ~/Code/dotfiles
nvim          # plugins install on first start
tmux          # prefix + I installs plugins
just system   # rerun once Claude is trusted: enables claude-remote.service
```

Optional: `atuin login`, Tailscale (`curl -fsSL https://tailscale.com/install.sh | sh && sudo tailscale up --ssh`).

### 6. Secrets and the leak guard

```bash
touch ~/.secrets.env && chmod 600 ~/.secrets.env        # auto-sourced, never committed
mkdir -p ~/.config/dotfiles && $EDITOR ~/.config/dotfiles/denylist
```

The repo is public. The pre-commit hook runs gitleaks and blocks staged lines
matching the denylist (employer, hostnames, work email; one regex per line).

### 7. Carry over

Not in git; copy from the old machine:

| Path             | What                                     |
| ---------------- | ---------------------------------------- |
| `~/.ssh/`        | keys, plus `config.local` for work hosts |
| `~/.secrets.env` | API keys, work env vars                  |
| `~/.kube/config` | cluster credentials                      |
| `~/.aws/`        | cloud credentials                        |
| `~/Code/`        | the actual work                          |
| shell history    | `atuin sync`, or copy `~/.zsh_history`   |

### 8. Verify

```bash
just doctor    # links, gitconfig, Claude settings, hooks, units, mise; prints each fix
```

### No sudo (shared servers)

```bash
./bootstrap-user.sh    # static zsh if missing, oh-my-zsh, CLI tools as mise binaries
./install.sh
```

Add `--work` on a company machine: Copilot replaces Claude everywhere. The
Windows-laptop-plus-build-server setup is in [WINDOWS_GUIDE.md](WINDOWS_GUIDE.md#work-laptop-thin-client).

### Ubuntu 22.04

Prebuilt tree-sitter needs glibc 2.39+:
`sudo apt install -y libclang-dev && cargo install tree-sitter-cli`.

## Daily use

Three layers, each doing what it is good at:

| Layer  | Owns                                   | Examples                                 |
| ------ | -------------------------------------- | ---------------------------------------- |
| Ubuntu | desktop, drivers, hardware tools       | browser, Docker engine, flashers, serial |
| Nix    | per-project toolchains via `flake.nix` | compilers, protoc, kubectl, linters      |
| Docker | anything stateful and disposable       | Postgres, Redis, Kafka, Mosquitto        |

```bash
cd ~/Code/new-project
nix-init.sh       # flake.nix + .envrc from templates/
direnv allow      # toolchain appears on cd, vanishes on leave
cp ~/Code/dotfiles/templates/compose.yaml . && docker compose up -d
ccinit            # agent instructions (AGENTS.md + per-tool files), git-excluded
```

`.envrc` is `use flake` (cached by nix-direnv) or `use mise` for quick scripts.

Serial consoles: `tio --list`, then `tio usb0` or `tio acm0` (profiles in `tio/config`).
It reconnects when the board resets; `Ctrl-t ?` for the menu, `Ctrl-t q` quits.

## AI agents

Claude Code is the personal default; work machines get Copilot through the
same entry points (`ai`, tmux `prefix + a`, Neovim `Space a`).

| Command  | Does                                        |
| -------- | ------------------------------------------- |
| `ai`     | Claude Code (Copilot on work)               |
| `aic`    | continue the last session                   |
| `ccr`    | remote control from claude.ai/code          |
| `ccinit` | copy agent instruction templates            |
| `agy`    | Antigravity, with the git root as workspace |

Config lives in `claude/`: global `CLAUDE.md`, base `settings.json`, statusline,
hooks (block secret writes, format after edit, notify when done).

`AGENTS.md` is the single source of instructions, built on the four
[Karpathy principles](https://github.com/multica-ai/andrej-karpathy-skills):

| Tool        | Loads `AGENTS.md` via                         |
| ----------- | --------------------------------------------- |
| Codex       | native                                        |
| Claude Code | `CLAUDE.md` with `@AGENTS.md`                 |
| Gemini CLI  | `GEMINI.md` with `@./AGENTS.md`               |
| Antigravity | native (`GEMINI.md` loads too, no duplicate)  |
| Copilot     | native; `copilot-instructions.md` adds review |

Link-only pointers load nothing. Copilot Chat in JetBrains and Visual Studio
ignores `AGENTS.md`.

MCP servers (user scope, re-add on a new machine):

```bash
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp
claude mcp add --scope user playwright -- npx -y @playwright/mcp@latest
claude mcp add --scope user --transport http github https://api.githubcopilot.com/mcp/ \
  --header "Authorization: Bearer $(gh auth token)"
```

## Shortcuts

`Super+K` lists every custom hotkey, read live from dconf.

### Desktop

| Hotkey                     | Action                                    |
| -------------------------- | ----------------------------------------- |
| `Ctrl+Alt+T`               | Ghostty window                            |
| `Super+V`                  | clipboard history                         |
| `Super+Ctrl+E`             | emoji picker                              |
| `Super+Print`              | color pick to clipboard                   |
| `Super+Ctrl+Print`         | OCR a region to clipboard                 |
| `Super+Shift+Print`        | decode a QR code to clipboard             |
| `Super+Ctrl+R`             | countdown reminder                        |
| `Super+Ctrl+N` / `,` / `I` | night light / do not disturb / stay awake |
| `Super+Ctrl+D`             | yt-dlp the clipboard URL                  |
| `Super+Ctrl+Space`         | next wallpaper                            |
| `Super+Ctrl+A`             | Claude Code window                        |
| `Super+Ctrl+L`             | Solaar (Logitech pairing)                 |
| `Super+Shift+W/Y/C/M/X/S`  | WhatsApp/YouTube/Claude/Maps/X/Spotify    |
| `Super+T`                  | Tactile tiling grid                       |
| `Super+1..6` / `+Shift`    | go to / move window to workspace          |
| `Super+W` / `Super+L`      | close window / lock                       |

Web apps are `chrome --app` windows: `webapp-install.sh <Name> <URL>` adds one.

### Ghostty

| Hotkey                   | Action                    |
| ------------------------ | ------------------------- |
| ``Ctrl+` ``              | quick terminal (dropdown) |
| `Ctrl+Shift+P`           | command palette           |
| `Ctrl+Shift+Enter` / `\` | split right / down        |
| `Ctrl+Shift+Arrows`      | focus split               |
| `Ctrl+Shift+Z` / `E`     | zoom / equalize splits    |
| `Ctrl+Shift+PageUp/Down` | jump between prompts      |
| `Ctrl+Shift+,`           | reload config             |

### tmux (prefix `Ctrl-a`)

| Key                     | Action                               |
| ----------------------- | ------------------------------------ |
| `\|` / `-`              | split horizontal / vertical          |
| `h j k l` / `H J K L`   | move / resize panes                  |
| `f` / `p`               | session picker / project sessionizer |
| `a`                     | AI popup                             |
| `g` / `C-k` / `B` / `N` | lazygit / k9s / btop / nvim popup    |
| `[` then `v` / `y`      | copy mode: select / yank             |
| `F`                     | thumbs quick-copy                    |

Sessions survive reboots (resurrect + continuum). Basics: [TMUX_GUIDE.md](TMUX_GUIDE.md).

### zsh and Neovim

| Key                | Action                                          |
| ------------------ | ----------------------------------------------- |
| `Ctrl-R`           | atuin history                                   |
| `Ctrl-T` / `Alt-C` | fzf file / cd                                   |
| `CapsLock`         | compose: `caps m s` emoji, `caps space e` email |
| `Space ac` / `af`  | Neovim: toggle / focus Claude                   |
| `Space aa` / `ad`  | Neovim: accept / deny Claude diff               |

Everything else Neovim: [NVIM_GUIDE.md](NVIM_GUIDE.md).

## Commands

Aliases are kept to what shell history shows in use; type the rest in full.

```bash
z / zi | ls / ll / la / l (eza) | .. | c | py / pip | dc (docker compose)
k / kgp / kgd (OMZ kubectl) | kctx / kc <ctx> / kns / ksetns <ns> / kcur | kw / ke
logs <file> (lnav) | tdl (tmux: nvim + AI + shell)
remind.sh 7 "tea"          # desktop reminder in 7 minutes
db.sh up|psql|redis|down   # throwaway postgres 18 + redis on localhost
dotf <target>              # any just target from anywhere
```

## Hardware

`bin/hw-profile.sh` gates everything hardware-specific; `just hw` prints it.

| Gate                               | True when                                      |
| ---------------------------------- | ---------------------------------------------- |
| `is_laptop` / `is_desktop`         | battery present / desktop chassis              |
| `is_wsl`                           | `WSL_DISTRO_NAME` or microsoft kernel          |
| `has_nvidia` / `has_amd_gpu` / ... | display-class PCI device with that vendor id   |
| `has_gui` / `has_desktop`          | graphical session / graphical install (no WSL) |
| `has_serial`                       | `/dev/ttyUSB*` or `/dev/ttyACM*` present       |
| `is_work`                          | `~/.config/dotfiles/work` exists               |

| GPU    | `just gpu` installs                                         |
| ------ | ----------------------------------------------------------- |
| NVIDIA | `nvidia-driver-580`, VA-API, `modeset=1`, suspend-safe VRAM |
| AMD    | Mesa, RADV, `radeonsi` VA-API/VDPAU, 32-bit halves          |
| Intel  | Mesa, Vulkan, `iHD` media driver, 32-bit halves             |

- Hybrid laptops get PRIME offload: `prime-run <cmd>` runs one program on the dGPU.
- Other NVIDIA branch: `NVIDIA_BRANCH=595 ./bin/gpu-setup.sh`.
- `just tune` sets `amd_pstate=active` and EPP `balance_performance` (desktop)
  or `balance_power` (laptop); override with `EPP=performance just tune`.

## Extras

### Backups (restic to Backblaze B2, daily)

```bash
# ~/.secrets.env: RESTIC_REPOSITORY, RESTIC_PASSWORD, B2_ACCOUNT_ID, B2_ACCOUNT_KEY
backup.sh init
just system                        # enables backup.timer once RESTIC_REPOSITORY is set
backup.sh snapshots / restore ~/restore-here
```

Covers what exists nowhere else (`~/Documents`, `~/Pictures`, `~/.ssh`,
`~/.kube`, `~/.aws`, secrets, history); `~/Code` lives in git. Keep the restic
passphrase in Bitwarden, off this machine.

### Apps

```bash
sudo snap install spotify discord obs-studio slack signal-desktop bruno dbeaver-ce localsend bitwarden
sudo apt install -y vlc wireshark xournalpp gnome-tweaks
just gaming                        # Steam, Lutris, Heroic, GameMode, MangoHud
just wallpapers "tokyo neon" 25
just clean                         # report reclaimable disk; clean-all deletes
```

Chrome extensions are forced from `chrome/extensions.txt` by managed policy.

## Maintenance

```bash
just update    # apt, brew, mise, rustup, claude, nvim plugins, tmux plugins, nix gc
just doctor    # drift report
just lint && just test
```

- **Migrations:** drop a script in `migrations/`; `just update` runs it once per
  machine (`migrate.sh --pending` lists unrun ones).
- **Renovate** opens grouped bump PRs for mise tools, Docker images, and
  Actions on Mondays.
- **CI** runs lint, gitleaks over the full history, bats tests, and an
  install idempotency test in Ubuntu 24.04.
