# --- WSL: bridge clipboard and browser to Windows ---
if [[ -n ${WSL_DISTRO_NAME:-} ]]; then
  # xclip/xsel do not exist without an X server; clip.exe and powershell do
  alias pbcopy='clip.exe'
  pbpaste() { powershell.exe -NoProfile -Command Get-Clipboard | tr -d '\r' }
  alias xclip='clip.exe'
  alias open='explorer.exe'
  export BROWSER='wslview'
  # Windows drives are slow: warn if a repo lives on /mnt/c
  [[ $PWD == /mnt/* ]] && echo "note: /mnt is the Windows filesystem - builds here are much slower"
fi
