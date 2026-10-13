# --- Claude Code (Copilot on a work machine, via ai.sh) ---
alias ai='ai.sh'
alias aic='ai.sh --continue'
alias ccr='claude remote-control --name "dev-session"'

# agy -p has no workspace (so no AGENTS.md) unless one is added
agy() { command agy --add-dir "$(git rev-parse --show-toplevel 2>/dev/null || print -r -- "$PWD")" "$@" }

typeset -g _dotfiles_templates="${${(%):-%x}:A:h:h}/templates"

# Copy AGENTS.md plus the file each agent in use here needs (Codex reads
# AGENTS.md as is), excluded via .git/info/exclude so .gitignore is untouched
ccinit() {
  local root gitdir f
  local -a files=(AGENTS.md)
  if [[ -f ~/.config/dotfiles/work ]]; then
    files+=(.github/copilot-instructions.md)
  else
    files+=(CLAUDE.md)
  fi
  (( $+commands[gemini] )) && files+=(GEMINI.md)
  root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "Not a git repo"; return 1 }
  gitdir=$(git rev-parse --path-format=absolute --git-common-dir)
  mkdir -p "$gitdir/info"
  for f in $files; do
    if [[ -f "$root/$f" ]]; then
      echo "$f already exists"
    else
      mkdir -p "${root}/${f:h}" && cp "$_dotfiles_templates/$f" "$root/$f" && echo "Created $root/$f"
    fi
    grep -qx "$f" "$gitdir/info/exclude" 2>/dev/null || echo "$f" >> "$gitdir/info/exclude"
  done
  echo "${(j:, :)files} excluded via $gitdir/info/exclude"
}
