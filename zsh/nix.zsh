# Nix aliases and functions

# --- Nix Build Functions ---
# nbuild <attr>       build flake attr, verbose (nbuild pkg -> .#pkg)
# nbuild_a64 <pkg>    cross/native build for aarch64-linux
nbuild() {
  local name="${1:?Usage: nbuild <attr> [extra-args...]}"
  shift
  nix build ".#$name" -vL "$@"
}

nbuild_a64() {
  local name="${1:?Usage: nbuild_a64 <pkg> [extra-args...]}"
  shift
  nix build ".#packages.aarch64-linux.$name" -vL "$@"
}

# --- Nix Formatting ---
nixfmt()      { alejandra "${1:-.}" }
nixfmttree()  { nix run nixpkgs#nixfmt-tree -- "${1:-.}" }
nixfmtall()   { alejandra "${1:-.}" && nix run nixpkgs#nixfmt-tree -- "${1:-.}" }
nixfmtcheck() { alejandra --check "${1:-.}" }
nixlint()     { nix run nixpkgs#statix -- check "${1:-.}" }
nixlintfix()  { nix run nixpkgs#statix -- fix "${1:-.}" }
nixdead()     { nix run nixpkgs#deadnix -- "${1:-.}" }
nixdeadfix()  { nix run nixpkgs#deadnix -- -e "${1:-.}" }
nixclean()    { nixfmtall "${1:-.}" && nixlint "${1:-.}" && nixdead "${1:-.}" }

# --- Nix Flake ---
upinput() { nix flake update "$@" }
alias flakeshow='nix flake show'
alias flakecheck='nix flake check'
alias flakemeta='nix flake metadata'
alias flakelock='nix flake lock'

# --- Nix Store ---
alias qreferrers='sudo $(which nix-store) --query --referrers'
alias qreferences='sudo $(which nix-store) --query --references'
alias qrequisites='nix-store --query --requisites'
alias qtree='nix-store --query --tree'
alias qsize='nix path-info -Sh'
alias qclosure='nix path-info -rSh'
alias nixgc='nix-collect-garbage -d'
alias nixgcold='nix-collect-garbage --delete-older-than 7d'
alias nixopt='nix-store --optimise'
alias nixrepair='nix-store --verify --check-contents --repair'
alias nixroots='nix-store --gc --print-roots | grep -v censored'
alias nixstoredu='df -h /nix/store && echo "---" && nix path-info --all -Sh 2>/dev/null | sort -hk2 | tail -20'

# --- Nix Dev ---
alias nixshell='nix-shell --run zsh'
alias nixdev='nix develop'
alias nixdevsh='nix develop --command zsh'
alias nixsearch='nix search nixpkgs'
alias nixrepl='nix repl'
alias nixlog='nix log'
alias nixwhy='nix why-depends'

# --- Nix Build Helpers ---
alias nixb='nix build'
alias nixbv='nix build -vL'
alias nixbimp='nix build --impure'
alias nixbvimp='nix build -vL --impure'
alias nixbdry='nix build --dry-run'
alias nixbtrace='nix build --show-trace -vL'

# --- Result Inspection ---
alias lsresult='ls -la ./result/ 2>/dev/null || echo "No result link"'
alias treeresult='tree -L 2 ./result/ 2>/dev/null || ls -laR ./result/ 2>/dev/null'
alias sizeresult='du -sh ./result/* 2>/dev/null'

# Diff two nix derivations
nixdiff() {
  [[ $# -ne 2 ]] && { echo "Usage: nixdiff <drv1> <drv2>"; return 1 }
  nix-diff "$1" "$2" 2>/dev/null || diff <(nix path-info -r "$1" | sort) <(nix path-info -r "$2" | sort)
}
