# Desktop-only: GUI apps, gaming, consumer VPN. Servers and WSL skip this file.
(( $+commands[gnome-shell] )) || return 0

alias gt='nohup ghostty >/dev/null 2>&1 & disown'
alias headlamp="$HOME/Apps/headlamp/headlamp.AppImage"

# --- Fun ---
alias matrix='cmatrix -ab -C cyan'
alias pipes='pipes.sh -p 5 -R -t 1'
alias bonsai='cbonsai -l -i -t 0.02'
alias visualizer='cava'

# Apple keyboards: F-keys act as function keys, not media keys
alias fix_fkeys='echo 2 | sudo tee /sys/module/hid_apple/parameters/fnmode'

# NordVPN (install: curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh | sh)
alias nvon='nordvpn connect'
alias nvoff='nordvpn disconnect'
alias nvstatus='nordvpn status'

# Run a command with GameMode (CPU governor + IO priority) and an FPS overlay
alias gmode='gamemoderun'
alias gmodehud='MANGOHUD=1 gamemoderun'

wifipass() {
  nmcli -s -g 802-11-wireless-security.psk connection show \
    "$(nmcli -t -f NAME,TYPE connection show --active | awk -F: '$2 ~ /wireless/ {print $1; exit}')"
}
