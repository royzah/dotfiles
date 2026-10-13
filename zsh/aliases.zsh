# General aliases. Kept to what shell history shows in use; type the rest in full.

if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --git --group-directories-first'
  alias ll='eza --icons --git -l --group-directories-first'
  alias la='eza --icons --git -la --group-directories-first'
  alias l='eza -F --icons --group-directories-first'
fi

alias ..='cd ..'
alias docs='cd ~/Documents'
alias c='clear'
alias df='df -h'
alias free='free -h'
alias wget='wget -c'
alias py='python3'
alias pip='pip3'
alias dc='docker compose'
