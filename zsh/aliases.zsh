# General aliases: files, navigation, system, git extras

# --- Files & Viewing ---
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --git --group-directories-first'
  alias ll='eza --icons --git -l --group-directories-first'
  alias la='eza --icons --git -la --group-directories-first'
  alias lt='eza --icons --git -l --tree --level=2'
  alias ltt='eza --icons --git -l --tree --level=3'
  alias l='eza -F --icons --group-directories-first'
fi
alias b='bat --style=plain --paging=never'
alias duu='dust'
alias jl='jless'
alias v='nvim'

# --- Navigation ---
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias dev='cd ~/Code'
alias src='cd ~/src'
alias docs='cd ~/Documents'
alias dl='cd ~/Downloads'
alias tmp='cd /tmp'

# --- Basic ---
alias c='clear'
alias h='history'
please() { sudo zsh -c "$(fc -ln -1)" }
alias apt-update='sudo apt update && sudo apt upgrade -y'
alias ports='ss -tulnp'
alias myip='curl -s ifconfig.me && echo'
localip() { hostname -I | awk '{print $1}' }
alias df='df -h'
alias free='free -h'
alias wget='wget -c'
alias headers='curl -sI'

# --- Git (extras beyond OMZ git plugin) ---
# OMZ provides: ga, gaa, gc, gcm, gco, gcb, gd, gf, gm, gp, gpf, gst (status), etc.
alias lg='lazygit'
alias glog='git log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit -20'

# --- Debugging / Network ---
alias http='http --style=monokai'
alias sniff='tcpdump -i any -n -c 100'

# --- System ---
alias top='btop'
alias fetch='fastfetch'
