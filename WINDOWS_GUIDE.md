# Windows Guide

Windows owns the desktop; Linux does the work. Pick the path that fits the machine:

| Machine                                    | Linux runs in             | Path                                                 |
| ------------------------------------------ | ------------------------- | ---------------------------------------------------- |
| Personal Windows PC                        | WSL 2, on this machine    | [Personal Windows: WSL](#personal-windows-wsl)       |
| Work laptop, code on a remote build server | the build server, via SSH | [Work laptop: thin client](#work-laptop-thin-client) |

Both start with [Windows setup](#windows-setup). Checked October 2026 against
Windows 11 25H2, WSL 3.0.

- [Windows setup](#windows-setup) - [Personal Windows: WSL](#personal-windows-wsl) -
  [Work laptop: thin client](#work-laptop-thin-client) - [Hotkey map](#hotkey-map) -
  [Tips worth keeping](#tips-worth-keeping) - [Troubleshooting](#troubleshooting)

## Windows setup

### 1. Run the laptop script

Per user, no admin, idempotent: apps via winget, Hack Nerd Font, Catppuccin
for Windows Terminal, VS Code extensions, End Task on the taskbar, and
`.wslconfig` on personal machines.

```powershell
iwr https://raw.githubusercontent.com/royzah/dotfiles/main/windows/laptop.ps1 -OutFile laptop.ps1
notepad laptop.ps1                                  # read it before running it
powershell -ExecutionPolicy Bypass -File .\laptop.ps1                          # personal
powershell -ExecutionPolicy Bypass -File .\laptop.ps1 -BuildHost build.example # work
```

`Bypass` applies to that one run. Anything winget cannot install per user is
listed at the end: get it from Company Portal (work) or an admin winget (personal).

### 2. Settings (personal; on work, whatever IT allows)

Settings > System > Advanced:

| Toggle             | Why                                                           |
| ------------------ | ------------------------------------------------------------- |
| End task           | already set by the script; kill apps from the taskbar         |
| Enable long paths  | deep `node_modules` and build trees stop breaking             |
| PowerShell scripts | same as `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| Enable sudo        | `sudo <cmd>` in a new elevated window                         |

Then: Power mode **Best performance** when plugged in, and Windows Terminal
settings (`Ctrl+,`): delete the `Ctrl+V` action so Neovim keeps visual block
(paste stays on `Ctrl+Shift+V`).

## Personal Windows: WSL

The whole Linux setup, unchanged, inside WSL 2. Windows Terminal is the
terminal (Ghostty has no Windows build).

### 1. Install WSL with Ubuntu 26.04

Admin PowerShell, then reboot and create the Linux user:

```powershell
wsl --install -d Ubuntu-26.04
```

### 2. Tune WSL

The laptop script already wrote `%UserProfile%\.wslconfig` (it never overwrites
one): mirrored networking (localhost, LAN and VPNs work both ways), gradual
memory reclaim, a self-shrinking disk image, and `127.0.0.1` reaching Windows
services. Memory stays at the default half of RAM; add `memory=` under `[wsl2]`
or use the **WSL Settings** app to change it. `wsl --shutdown` applies changes.
DNS tunneling, the firewall, and auto proxy are on by default.

### 3. Install the dotfiles inside Ubuntu

```bash
ps -p 1 -o comm=    # must print systemd; else add [boot] systemd=true to /etc/wsl.conf, wsl --shutdown
```

Then follow [LINUX_GUIDE.md: Install](LINUX_GUIDE.md#install) steps 1, 2, 3
(`./install.sh` only), 5, 6, and 8. The scripts detect WSL: desktop packages,
`setup-system.sh`, and `just tune` are skipped, and Docker Engine is installed
inside WSL (no Docker Desktop, no license terms).

### 4. Work in it

| Do                                    | Why                                            |
| ------------------------------------- | ---------------------------------------------- |
| Keep code in `~/Code`, never `/mnt/c` | crossing the filesystem boundary is far slower |
| `code .` from WSL                     | VS Code on Windows, files and tools in Linux   |
| `nvim` + tmux in Windows Terminal     | identical to Ubuntu                            |
| Install only the Windows GPU driver   | CUDA and Vulkan reach WSL through it           |
| `usbipd` for USB serial devices       | attaches a board's USB port to WSL             |

Clipboard is bridged: `pbcopy`/`pbpaste` map to `clip.exe` and PowerShell,
`open` maps to `explorer.exe`.

| Works in WSL                                | Windows owns instead                |
| ------------------------------------------- | ----------------------------------- |
| zsh, tmux, Neovim, git, lazygit, fzf, atuin | hotkeys, tiling, clipboard history  |
| Nix, mise, direnv, Docker, Claude Code      | Ghostty, GNOME extensions, web apps |
| tio (with `usbipd`)                         | Solaar, gaming, `just tune`         |

## Work laptop: thin client

The laptop renders text; a remote Linux build server runs this repo. WSL may
be blocked by Intune, and company code should stay on the build server anyway.

### Ground rules

| Company rule                          | How this setup stays inside it                                    |
| ------------------------------------- | ----------------------------------------------------------------- |
| No personal GitHub on company devices | the repo is public and pulled anonymously; nothing pushes         |
| Code never leaves company systems     | Claude, its remote control, and restic backups are off at work    |
| Only approved AI on company code      | `--work` swaps Claude for Copilot in tmux, zsh, and Neovim        |
| Software from Company Portal          | the script tries winget per user and lists the rest               |
| TLS-inspecting proxy                  | `https_proxy` and the CA bundle in `~/.secrets.env` on the server |

Ask IT once: can the build server reach github.com (release downloads)?

### 1. SSH key to the server

The script created the key and a `Host build` entry. Copy the key once:

```powershell
Get-Content ~\.ssh\id_ed25519.pub |
  ssh build "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
ssh build hostname    # no password prompt now
```

- Key passphrase: the `ssh-agent` service remembers it (admin once:
  `Set-Service ssh-agent -StartupType Automatic; Start-Service ssh-agent`, then `ssh-add`).
- Kerberos-only farms: skip the copy; `ssh build` uses the Windows login.

### 2. Build server (no sudo)

```bash
export https_proxy=http://proxy.example:8080   # if IT says so; keep it in ~/.secrets.env
export MISE_GITHUB_TOKEN=github_pat_...        # work account, no scopes: lifts the API rate limit
git clone https://github.com/royzah/dotfiles.git ~/Code/dotfiles
git -C ~/Code/dotfiles remote set-url --push origin no-push   # this machine never pushes
cd ~/Code/dotfiles && ./bootstrap-user.sh --work && ./install.sh && exec zsh -l
```

Work identity in the untracked `~/.gitconfig.local`:

```ini
[user]
  email = first.last@company.example
[commit]
  gpgsign = false    # the personal signing key never goes on a work machine
```

`--work` writes `~/.config/dotfiles/work`: Copilot replaces Claude in `ai`,
`tdl`, tmux `prefix + a`, and Neovim; `just hw` shows `profile: work`.
Docker, Nix, and brew need root: ask IT about rootless Podman.

### 3. Copilot (work account everywhere)

| Where    | How                                              |
| -------- | ------------------------------------------------ |
| Terminal | `copilot` then `/login`; `ai` / `aic` run it too |
| tmux     | `prefix + a` popup                               |
| Neovim   | `:Copilot auth` once; chat on `Space a`          |
| VS Code  | Remote-SSH to `build`, Copilot agent mode        |

### 4. Daily loop

1. Windows Terminal, **Build server** profile (set it as default): lands in tmux
   `main`, which survives sleep, VPN drops, and laptop reboots.
2. Work as on Ubuntu: `tdl`, `prefix + p`, `prefix + g`.
3. GUI editing: VS Code `F1` > Remote-SSH: Connect to Host > `build`.

Yanks in tmux and Neovim reach the Windows clipboard over SSH (OSC 52).

### 5. Fast builds on a shared server

- Build trees and caches (`ccache`, Yocto `sstate-cache` and `DL_DIR`, cargo
  `target`) on local scratch (`/local`, `/scratch`), not the NFS home.
- Point Yocto `SSTATE_DIR` / `DL_DIR` at the team mirror if one exists.
- `nice -n 10` long builds; keep the shell snappy.
- VS Code Remote-SSH: exclude build output from watching and search:

  ```json
  "files.watcherExclude": { "**/build/**": true, "**/tmp/**": true, "**/sstate-cache/**": true },
  "search.exclude": { "**/build": true, "**/tmp": true, "**/sstate-cache": true }
  ```

### 6. Maintenance

```bash
cd ~/Code/dotfiles && git pull && ./bootstrap-user.sh --work && ./install.sh
mise upgrade && nvim --headless "+Lazy! sync" +qa
```

Laptop: `winget upgrade --all`, or Company Portal. Repo changes are made on a
personal machine; the server only pulls.

## Hotkey map

Ubuntu hotkeys from [LINUX_GUIDE.md](LINUX_GUIDE.md#shortcuts), on Windows:

| Ubuntu                      | Windows                                             |
| --------------------------- | --------------------------------------------------- |
| `Super` app search          | `Win`, or PowerToys Command Palette `Win+Alt+Space` |
| `Super+K` hotkey overlay    | PowerToys Shortcut Guide `Win+Shift+/`              |
| `Super+T` tiling            | Snap layouts `Win+Z`; FancyZones ``Win+Shift+` ``   |
| `Super+1..6` workspaces     | `Win+Ctrl+Left/Right`; new desktop `Win+Ctrl+D`     |
| `Super+V` clipboard history | `Win+V`                                             |
| `Super+Ctrl+E` emoji        | `Win+.`                                             |
| `Print` screenshot          | `Win+Shift+S`                                       |
| `Super+Ctrl+Print` OCR      | PowerToys Text Extractor `Win+Shift+T`              |
| `Super+Print` color pick    | PowerToys Color Picker `Win+Shift+C`                |
| `Super+Ctrl+I` stay awake   | PowerToys Awake                                     |
| ``Ctrl+` `` dropdown        | Windows Terminal quake mode ``Win+` ``              |

## Tips worth keeping

From popular Windows dev-setup guides, checked against this setup:

| Tip                                             | Verdict                                                                         |
| ----------------------------------------------- | ------------------------------------------------------------------------------- |
| winget instead of `.exe` installers             | yes: the laptop script; `winget export`/`import` moves a PC                     |
| Taskbar End Task, long paths                    | yes: [Settings](#2-settings-personal-on-work-whatever-it-allows)                |
| WSL 2 + VS Code on the Windows side             | yes: [Personal Windows](#personal-windows-wsl)                                  |
| PowerToys: Env Variables, Awake, File Locksmith | yes: installed by the script                                                    |
| Ultimate Performance power plan                 | desktops only: `powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61` |
| `uv` for Python                                 | yes: in `mise.toml`; `uv venv`, `uv pip`, `uvx`                                 |
| Docker Model Runner for local LLMs              | optional: `sudo apt install docker-model-plugin` in WSL                         |
| LocalSend (AirDrop between devices)             | yes: the script on personal Windows; snap on Ubuntu (Apps)                      |
| `Set-ExecutionPolicy Unrestricted`              | no: `RemoteSigned` for the current user                                         |
| nvm for Node                                    | no: mise already pins Node per project                                          |
| `iwr ... \| iex` debloat utilities              | no: download, read, then run; never on a managed laptop                         |
| Removing OneDrive, Widgets, Bing                | personal only: `winget uninstall` each; IT owns work images                     |
| Local account at setup (`BYPASSNRO`)            | skip: unreliable on current builds                                              |

## Troubleshooting

| Symptom                                 | Fix                                                                            |
| --------------------------------------- | ------------------------------------------------------------------------------ |
| Prompt shows boxes                      | Windows Terminal font is not Hack Nerd Font                                    |
| WSL: slow git or builds                 | the repo is under `/mnt/c`; move it to `~/Code`                                |
| WSL: services unreachable from Windows  | `networkingMode=mirrored`; IT policy may lock networking                       |
| WSL: timers or Docker do not start      | systemd is off: `/etc/wsl.conf` `[boot] systemd=true`, `wsl --shutdown`        |
| Build server tab closes at once         | run `ssh build` by hand to see the error                                       |
| `ssh build` asks for a password         | key not in `authorized_keys`, or the farm is Kerberos-only                     |
| `bootstrap-user.sh` cannot reach GitHub | set `https_proxy`; else ask IT to allow release downloads                      |
| mise: 403 rate limit                    | set `MISE_GITHUB_TOKEN`                                                        |
| TLS errors from curl, mise, npm, pip    | `SSL_CERT_FILE`, `NODE_EXTRA_CA_CERTS`, `REQUESTS_CA_BUNDLE` to the company CA |
| Copilot not authorized                  | personal account: `/logout`, `/login` with the work one                        |
| Commits show the personal email         | `~/.gitconfig.local` missing                                                   |
| tmux copy does not reach Windows        | needs Windows Terminal (OSC 52) and tmux 3.2+                                  |
