# --- Claude Code (Copilot on a work machine, via ai.sh) ---
alias ai='ai.sh'
alias aic='ai.sh --continue'
alias ccr='claude remote-control --name "dev-session"'

typeset -g _dotfiles_templates="${${(%):-%x}:A:h:h}/templates"

# Copy the agent instruction templates (AGENTS.md, plus the CLAUDE.md that
# imports it off work machines) into the current repo, excluded via
# .git/info/exclude so the shared .gitignore is untouched
ccinit() {
  local root gitdir f
  local -a files=(AGENTS.md)
  [[ -f ~/.config/dotfiles/work ]] || files+=(CLAUDE.md)
  root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "Not a git repo"; return 1 }
  gitdir=$(git rev-parse --path-format=absolute --git-common-dir)
  mkdir -p "$gitdir/info"
  for f in $files; do
    if [[ -f "$root/$f" ]]; then
      echo "$f already exists"
    else
      cp "$_dotfiles_templates/$f" "$root/$f" && echo "Created $root/$f"
    fi
    grep -qx "$f" "$gitdir/info/exclude" 2>/dev/null || echo "$f" >> "$gitdir/info/exclude"
  done
  echo "${(j:, :)files} excluded via $gitdir/info/exclude"
}
