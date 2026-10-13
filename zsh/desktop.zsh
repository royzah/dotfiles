# Desktop-only: GUI apps. Servers and WSL skip this file.
(( $+commands[gnome-shell] )) || return 0

alias headlamp="$HOME/Apps/headlamp/headlamp.AppImage"
alias pipes='pipes.sh -p 5 -R -t 1'
