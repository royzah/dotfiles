# laptop.ps1 - Windows side of these dotfiles. Per-user, no admin, idempotent.
#   Personal (WSL):        .\laptop.ps1
#   Work (thin client):    .\laptop.ps1 -BuildHost build-server.example
param(
  [string]$BuildHost = '',
  [string]$BuildUser = $env:USERNAME
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Work = [bool]$BuildHost

function Set-Reg([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord') {
  if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
  New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

Write-Host '[apps]'
$pkgs = 'Microsoft.WindowsTerminal', 'Microsoft.VisualStudioCode', 'Microsoft.PowerToys', 'Microsoft.PowerShell'
if (-not $Work) { $pkgs += 'LocalSend.LocalSend' }
$portal = @()
if (Get-Command winget -ErrorAction SilentlyContinue) {
  foreach ($id in $pkgs) {
    winget list --id $id -e --accept-source-agreements | Out-Null
    if ($LASTEXITCODE -eq 0) { Write-Host "  have: $id"; continue }
    winget install --id $id -e --scope user --silent --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) { $portal += $id }
  }
} else { $portal = $pkgs }
if ($portal) { Write-Warning "Install from Company Portal / Software Center / winget as admin: $($portal -join ', ')" }

Write-Host '[explorer + taskbar]'
$adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Set-Reg $adv 'HideFileExt' 0
Set-Reg $adv 'Hidden' 1
# Right-click a taskbar app > End task, without opening Task Manager
Set-Reg "$adv\TaskbarDeveloperSettings" 'TaskbarEndTask' 1

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

if ($Work) {
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
}

Write-Host '[terminal]'
# A fragment adds the theme (and the Build server profile) without touching settings.json.
# The PATH export finds a static zsh in ~/.local/bin: sshd runs a non-login shell.
$profiles = ''
if ($Work) {
  $profiles = @'
  ,"profiles": [
    {
      "name": "Build server",
      "commandline": "ssh -t build \"export PATH=$HOME/.local/bin:$PATH; exec zsh -lic 'tmux new-session -A -s main'\"",
      "colorScheme": "Catppuccin Mocha",
      "font": { "face": "Hack Nerd Font", "size": 11 }
    }
  ]
'@
}
$frag = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\Fragments\dotfiles'
New-Item -ItemType Directory -Force $frag | Out-Null
@"
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
  ]
$profiles}
"@ | Set-Content (Join-Path $frag 'dotfiles.json') -Encoding ascii
Write-Host '  Catppuccin Mocha scheme added'

Write-Host '[vscode]'
if (Get-Command code -ErrorAction SilentlyContinue) {
  $exts = @('Catppuccin.catppuccin-vsc')
  if ($Work) { $exts += 'ms-vscode-remote.remote-ssh', 'GitHub.copilot', 'GitHub.copilot-chat' }
  else { $exts += 'ms-vscode-remote.remote-wsl', 'anthropic.claude-code' }
  foreach ($ext in $exts) { code --install-extension $ext | Out-Null }
  Write-Host "  $($exts -join ', ')"
} else { Write-Host '  skipped: open a new PowerShell after VS Code installs, then rerun' }

Write-Host ''
if ($Work) { Write-Host 'Next: WINDOWS_GUIDE.md, copy the key to the build server.' }
else { Write-Host 'Next: WINDOWS_GUIDE.md, install WSL (admin PowerShell).' }
