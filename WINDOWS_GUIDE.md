# Windows Guide

For a job where the laptop must run Windows and the real work happens on a
remote Linux build server. The plan: **the laptop is a thin client, the build
server runs this repo.**

- **Windows laptop** owns the desktop, browser, Office/Teams, VPN, Windows
  Terminal, and VS Code (as a remote UI). No dotfiles repo lives here.
- **Build server** owns the shell, editor, git, toolchains, tmux sessions, and
  the builds. It gets this repo through `bootstrap-user.sh`, which needs no sudo.
- **AI** on work code is the company's GitHub Copilot, signed in with the work
  account. Personal Claude stays on personal machines.

Written September 2026 against Windows 11 24H2/25H2.

- [0. Ground rules](#0-ground-rules) - [1. Laptop script](#1-laptop-script) - [2. SSH](#2-ssh)
- [3. Build server](#3-build-server) - [4. Copilot](#4-copilot) - [5. Daily workflow](#5-daily-workflow)
- [6. Performance](#6-performance) - [7. Desktop map](#7-desktop-map) - [8. Maintenance](#8-maintenance)
- [9. Troubleshooting](#9-troubleshooting)

## 0. Ground rules

What big companies usually enforce, and how this setup stays inside it:

| Rule                                           | How this setup handles it                                                   |
| ---------------------------------------------- | --------------------------------------------------------------------------- |
| No personal GitHub on company devices          | The repo is public and pulled anonymously; nothing signs in, nothing pushes |
| Company code never leaves company systems      | Personal Claude, its remote control, and restic backups are off at work     |
| Only approved AI on company code               | `--work` swaps Claude for Copilot in tmux, zsh, and Neovim                  |
| Commits carry the work identity                | `~/.gitconfig.local` on the server sets the work email for every repo       |
| Software from Company Portal / Software Center | The laptop script tries winget per-user and tells you what to get there     |
| TLS-inspecting proxy (Zscaler, Netskope)       | Set `https_proxy` on the server; curl, git, and mise honor it               |

The one question still worth asking IT: **can the build server reach
github.com through the proxy?** `bootstrap-user.sh` downloads prebuilt tools
from GitHub releases and says so clearly if it cannot.

## 1. Laptop script

Per-user, no admin. Open this guide on github.com in the laptop browser
(reading a public page needs no account), save the block below as
`laptop.ps1`, set the two values at the top, then run it from PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process Bypass    # this window only; nothing persists
.\laptop.ps1
```

If group policy enforces `AllSigned`, paste the script into the console instead.

```powershell
# laptop.ps1 - Windows thin client for a remote Linux build server. Per-user, no admin. Idempotent.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$BuildHost = 'build-server.example'   # the real name from IT
$BuildUser = $env:USERNAME            # usually the same corporate login

function Set-Reg([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord') {
  if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
  New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

Write-Host '[apps]'
$pkgs = 'Microsoft.WindowsTerminal', 'Microsoft.VisualStudioCode', 'Microsoft.PowerToys', 'Microsoft.PowerShell'
$portal = @()
if (Get-Command winget -ErrorAction SilentlyContinue) {
  foreach ($id in $pkgs) {
    winget list --id $id -e --accept-source-agreements | Out-Null
    if ($LASTEXITCODE -eq 0) { Write-Host "  have: $id"; continue }
    winget install --id $id -e --scope user --silent --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) { $portal += $id }
  }
} else { $portal = $pkgs }
if ($portal) { Write-Warning "Install from Company Portal / Software Center: $($portal -join ', ')" }

Write-Host '[explorer]'
$adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Set-Reg $adv 'HideFileExt' 0
Set-Reg $adv 'Hidden' 1

Write-Host '[ssh]'
$sshDir = Join-Path $env:USERPROFILE '.ssh'
New-Item -ItemType Directory -Force $sshDir | Out-Null
$key = Join-Path $sshDir 'id_ed25519'
if (Test-Path $key) {
  Write-Host '  have: id_ed25519'
} else {
  Write-Host '  new key: pick a passphrase, or Enter for none'
  ssh-keygen -t ed25519 -f $key -C "$env:USERNAME@$env:COMPUTERNAME"
}
$cfg = Join-Path $sshDir 'config'
if ((Test-Path $cfg) -and (Select-String -Path $cfg -Pattern '^Host build$' -Quiet)) {
  Write-Host '  have: Host build'
} else {
  Add-Content -Path $cfg -Encoding ascii -Value @"

Host build
    HostName $BuildHost
    User $BuildUser
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 30
    ServerAliveCountMax 5
"@
  Write-Host "  added: Host build -> $BuildUser@$BuildHost"
}

Write-Host '[font]'
$fonts = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
if (Test-Path (Join-Path $fonts 'HackNerdFont-Regular.ttf')) {
  Write-Host '  have: Hack Nerd Font'
} else {
  $zip = Join-Path $env:TEMP 'Hack.zip'
  $dir = Join-Path $env:TEMP 'HackNF'
  Invoke-WebRequest 'https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip' -OutFile $zip
  Expand-Archive $zip $dir -Force
  New-Item -ItemType Directory -Force $fonts | Out-Null
  $reg = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
  Get-ChildItem $dir -Filter 'HackNerdFont*.ttf' | ForEach-Object {
    $dst = Join-Path $fonts $_.Name
    Copy-Item $_.FullName $dst -Force
    Set-Reg $reg "$($_.BaseName) (TrueType)" $dst 'String'
  }
  Write-Host '  installed (per user)'
}

Write-Host '[terminal]'
# A fragment adds the theme and a "Build server" profile without touching settings.json.
# The PATH export finds a static zsh in ~/.local/bin: sshd runs a non-login shell.
$frag = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\Fragments\dotfiles'
New-Item -ItemType Directory -Force $frag | Out-Null
@'
{
  "schemes": [
    {
      "name": "Catppuccin Mocha",
      "background": "#1E1E2E", "foreground": "#CDD6F4",
      "cursorColor": "#F5E0DC", "selectionBackground": "#585B70",
      "black": "#45475A", "red": "#F38BA8", "green": "#A6E3A1", "yellow": "#F9E2AF",
      "blue": "#89B4FA", "purple": "#F5C2E7", "cyan": "#94E2D5", "white": "#BAC2DE",
      "brightBlack": "#585B70", "brightRed": "#F38BA8", "brightGreen": "#A6E3A1",
      "brightYellow": "#F9E2AF", "brightBlue": "#89B4FA", "brightPurple": "#F5C2E7",
      "brightCyan": "#94E2D5", "brightWhite": "#A6ADC8"
    }
  ],
  "profiles": [
    {
      "name": "Build server",
      "commandline": "ssh -t build \"export PATH=$HOME/.local/bin:$PATH; exec zsh -lic 'tmux new-session -A -s main'\"",
      "colorScheme": "Catppuccin Mocha",
      "font": { "face": "Hack Nerd Font", "size": 11 }
    }
  ]
}
'@ | Set-Content (Join-Path $frag 'dotfiles.json') -Encoding ascii
Write-Host '  theme + Build server profile added'

Write-Host '[vscode]'
if (Get-Command code -ErrorAction SilentlyContinue) {
  foreach ($ext in 'ms-vscode-remote.remote-ssh', 'GitHub.copilot', 'GitHub.copilot-chat', 'Catppuccin.catppuccin-vsc') {
    code --install-extension $ext | Out-Null
  }
  Write-Host '  Remote-SSH, Copilot, Catppuccin'
} else { Write-Host '  skipped: open a new PowerShell after VS Code installs, then rerun' }

Write-Host ''
Write-Host 'Next: section 2 (copy the key to the server).'
```

Then in Windows Terminal settings (`Ctrl+,`): **Startup > Default profile**
= Build server, and under **Actions** delete the `Ctrl+V` binding so Neovim
keeps visual block (paste stays on `Ctrl+Shift+V`).

## 2. SSH

Windows ships OpenSSH. Copy the key to the server once (asks for your password
one last time; there is no `ssh-copy-id` on Windows):

```powershell
Get-Content ~\.ssh\id_ed25519.pub |
  ssh build "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
ssh build hostname    # should not ask for a password now
```

- **Passphrase on the key:** the Windows `ssh-agent` service remembers it, but
  enabling that service needs admin once:
  `Set-Service ssh-agent -StartupType Automatic; Start-Service ssh-agent`, then
  `ssh-add`. Without it, every connection asks.
- **Kerberos / AD login instead of keys:** some build farms disable keys. Then
  skip the copy; `ssh build` uses your Windows login and the rest is the same.
- **ControlMaster** from the repo's `ssh_config` does not exist in Windows
  OpenSSH; VS Code and tmux keep one long connection anyway.

## 3. Build server

Everything here runs on the server, in your home directory, without sudo.

```bash
export https_proxy=http://proxy.example:8080    # only if IT says so; also put it in ~/.secrets.env
# mise resolves versions via the GitHub API: 60 calls/hour per IP anonymously,
# shared by everyone behind the office IP. A fine-grained token from the WORK
# github.com account with no permissions (public data only) lifts that:
export MISE_GITHUB_TOKEN=github_pat_...         # keep it in ~/.secrets.env too

# Anonymous, read-only clone of the public repo. The push URL is disabled so
# this machine can never push to a personal remote.
git clone https://github.com/royzah/dotfiles.git ~/Code/dotfiles
git -C ~/Code/dotfiles remote set-url --push origin no-push

cd ~/Code/dotfiles
./bootstrap-user.sh --work    # zsh, oh-my-zsh, mise + every CLI tool, Copilot CLI
./install.sh                  # link configs (Claude config skipped on work)
exec zsh -l
```

What `--work` does: writes the marker `~/.config/dotfiles/work`, which
`hw-profile.sh` exposes as `is_work`. That swaps `cc`, `tdl`, and tmux
`prefix + a` to Copilot, loads LazyVim's Copilot extras instead of
claudecode.nvim, skips the Claude install and config, and adds the Copilot CLI
through a machine-local mise file. `just hw` shows `profile: work`.

What `bootstrap-user.sh` gives you without root:

| Piece                              | Where it comes from                                             |
| ---------------------------------- | --------------------------------------------------------------- |
| zsh                                | System zsh, else a static build in `~/.local` (romkatv/zsh-bin) |
| Login shell                        | `~/.bashrc` enters zsh for interactive shells (no chsh needed)  |
| nvim, tmux, starship, fzf, rg, ... | Prebuilt binaries via mise, listed in `mise-cli.toml`           |
| Go, Node, Python                   | mise, from the repo's `mise.toml`                               |
| Copilot CLI                        | mise `npm:@github/copilot`, work machines only                  |

Not on the server: Docker, Nix, and Homebrew need root; ask IT whether rootless
Podman or a shared toolchain module exists. `just update` uses sudo too; see
[Maintenance](#8-maintenance) for the no-sudo loop.

### Work identity

The tracked `gitconfig` is personal. On the server, override it for every repo
with the untracked `~/.gitconfig.local` (included last, so it wins):

```ini
[user]
  name = Your Name
  email = first.last@company.example
[commit]
  gpgsign = false    # the personal signing key never goes on a work machine
```

Company hosts and env go in the usual untracked places: `~/.ssh/config.local`
for hosts, `~/.secrets.env` for `https_proxy`, `GOPRIVATE`, and CA bundles. If
the company git is GitHub Enterprise:
`gh auth login --hostname github.company.example` with the work account.

## 4. Copilot

Signed in with the **work** GitHub account everywhere:

| Where    | How                                                                      |
| -------- | ------------------------------------------------------------------------ |
| Terminal | `copilot`, then `/login`. `cc` runs it too; `ccc` continues last session |
| tmux     | `prefix + a` opens Copilot in a popup in the current directory           |
| Neovim   | `:Copilot auth` once; inline suggestions plus Copilot Chat on `Space a`  |
| VS Code  | Copilot and Copilot Chat extensions, agent mode, over Remote-SSH         |

Copilot's model picker usually includes Claude models when the company admin
allows them. "Unlimited" plans can still meter premium models per month.

## 5. Daily workflow

1. Open Windows Terminal: the default **Build server** tab lands in tmux session
   `main`, which survives laptop sleep, VPN drops, and laptop reboots.
2. Work exactly like on Ubuntu: `tdl` for nvim + AI + shell, `prefix + p`
   project picker, lazygit on `prefix + g`.
3. For GUI editing, VS Code: `F1` > **Remote-SSH: Connect to Host** > `build`,
   then open the repo. The terminal inside VS Code is the server.

Clipboard works over SSH through Windows Terminal (OSC 52): tmux copy mode `y`,
tmux-thumbs, and Neovim yanks land in the Windows clipboard. For URLs,
`Ctrl+click` them in Windows Terminal; thumbs "open" (`Shift` + hint) has no
browser on a headless server, so use plain thumbs to copy instead.

## 6. Performance

The server is strong; the usual bottlenecks are disk and file watching.

- **Build on local disk, not the NFS home.** Home directories on build farms
  are usually network mounts. Ask where local scratch is (`/local`, `/scratch`,
  NVMe `/tmp`), put build trees and caches there (`ccache`, Yocto
  `sstate-cache` and `DL_DIR`, cargo `target`), and keep sources and config in
  home.
- **Share caches.** Point Yocto `SSTATE_DIR` and `DL_DIR` at the team's shared
  mirror if one exists; it turns hours into minutes.
- **Right-size parallelism** on a shared box: `nproc` shows the cores, and
  `nice -n 10` keeps interactive work snappy during long builds.
- **VS Code Remote-SSH** watches every file by default. Exclude build output in
  the remote settings, or large trees pin a core:

  ```json
  "files.watcherExclude": { "**/build/**": true, "**/tmp/**": true, "**/sstate-cache/**": true, "**/downloads/**": true },
  "search.exclude": { "**/build": true, "**/tmp": true, "**/sstate-cache": true }
  ```

- **Laptop:** plugged in, Settings > System > Power > Best performance, and
  trim the startup apps IT allows. The laptop mostly renders text.

## 7. Desktop map

Where each Ubuntu/GNOME hotkey from the README went. Most come from PowerToys.

| On Ubuntu here                | On Windows                                               |
| ----------------------------- | -------------------------------------------------------- |
| `Super` app search            | `Win`, or PowerToys Command Palette `Win+Alt+Space`      |
| `Super+K` hotkey overlay      | PowerToys Shortcut Guide `Win+Shift+/`                   |
| Tactile tiling `Super+T`      | Snap layouts `Win+Z`; FancyZones editor ``Win+Shift+` `` |
| `Super+1..6` workspaces       | `Win+Ctrl+Left/Right`, new desktop `Win+Ctrl+D`          |
| `Super+V` clipboard history   | `Win+V` (turn on history the first time)                 |
| `Super+Ctrl+E` emoji          | `Win+.`                                                  |
| `Print` screenshot            | `Win+Shift+S`                                            |
| `Super+Ctrl+Print` OCR        | PowerToys Text Extractor `Win+Shift+T`                   |
| `Super+Print` color pick      | PowerToys Color Picker `Win+Shift+C`                     |
| `Super+Ctrl+I` stay awake     | PowerToys Awake (tray icon)                              |
| `Super+Ctrl+N` night light    | Quick settings `Win+A`                                   |
| `Super+Ctrl+,` do not disturb | Notification center `Win+N`, Do not disturb              |
| `Super+L` / `Super+W`         | `Win+L` / `Alt+F4`                                       |
| `Super+Up` / `Super+Down`     | `Win+Up` / `Win+Down`                                    |
| ``Ctrl+` `` Ghostty dropdown  | Windows Terminal quake mode ``Win+` ``                   |
| Ghostty tabs `Alt+1..9`       | Windows Terminal `Ctrl+Alt+1..9`                         |
| Vitals top-bar meters         | Task Manager `Ctrl+Shift+Esc`; `btop` on the server      |

Everything terminal-side - tmux, zsh, Neovim, lazygit, the aliases - is the
same as the README, just on the server.

## 8. Maintenance

Laptop, monthly: `winget upgrade --all`, or Company Portal updates.

Server, whenever the repo changes (all no-sudo):

```bash
cd ~/Code/dotfiles && git pull          # anonymous, read-only
./bootstrap-user.sh --work && ./install.sh
mise upgrade                            # CLI tools, runtimes, Copilot CLI
nvim --headless "+Lazy! sync" +qa
```

Changes to the repo itself are made on a personal machine and pushed from
there; the server only ever pulls.

## 9. Troubleshooting

| Symptom                                      | Fix                                                                                                             |
| -------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `bootstrap-user.sh`: cannot reach github.com | Set `https_proxy`; if it still fails, ask IT to allow GitHub release downloads                                  |
| mise: 403 / API rate limit exceeded          | `MISE_GITHUB_TOKEN` from the work account (section 3), then rerun                                               |
| TLS errors from curl, mise, npm, pip         | Point `SSL_CERT_FILE`, `NODE_EXTRA_CA_CERTS`, `REQUESTS_CA_BUNDLE` at the company CA bundle in `~/.secrets.env` |
| Prompt shows boxes                           | Terminal font is not Hack Nerd Font (the fragment sets it on Build server)                                      |
| Build server tab closes at once              | Run `ssh build` by hand to see the error; check `~/.local/bin/zsh` or system zsh                                |
| `ssh build` still asks for a password        | Key not in `~/.ssh/authorized_keys`, or the farm uses Kerberos only (section 2)                                 |
| Tools missing in a new shell                 | `mise doctor`; the zshrc activates mise before starship, fzf, and zoxide                                        |
| Copilot says not authorized                  | Signed in with a personal account: `/logout`, then `/login` with the work one                                   |
| Commits show the personal email              | `~/.gitconfig.local` missing; `git config user.email` inside the repo to check                                  |
| Copying in tmux does not reach Windows       | Needs Windows Terminal and tmux 3.2+ (mise installs a current one)                                              |
