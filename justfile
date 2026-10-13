set shell := ["bash", "-cu"]

default:
    @just --list

# Tracked plus new (not ignored) files, so a file is linted before its first commit
files := "git ls-files --cached --others --exclude-standard"

lint:
    shellcheck -x $({{files}} '*.sh' '.githooks/*')
    shfmt -d $({{files}} '*.sh' '*.bats' '.githooks/*')
    shellcheck -s bash -x $({{files}} '*.bats')
    for f in zshrc $({{files}} 'zsh/*.zsh'); do zsh -n "$f"; done
    luacheck nvim/ --quiet
    stylua --config-path nvim/stylua.toml --check nvim/
    markdownlint $({{files}} '*.md')
    jq empty claude/settings.json nvim/lazyvim.json renovate.json
    gitleaks git --no-banner --redact .

test:
    bats tests/

# Report drift between this machine and what install/setup would produce
doctor:
    ./bin/doctor.sh

fmt:
    shfmt -w $({{files}} '*.sh' '*.bats' '.githooks/*')
    stylua --config-path nvim/stylua.toml nvim/

# Update everything (system, CLI tools, runtimes, editor, AI); skips what is missing, so no sudo needed. Run monthly.
update:
    #!/usr/bin/env bash
    set -euo pipefail
    source bin/hw-profile.sh
    have() { command -v "$1" > /dev/null 2>&1; }
    if have apt-get && [[ " $(id -nG) " == *" sudo "* ]]; then sudo apt-get update && sudo apt-get upgrade -y; fi
    if have brew; then brew update && brew upgrade; fi
    if have mise; then mise upgrade; fi
    if have rustup; then rustup update; fi
    if have claude && ! is_work; then claude update; fi
    if have nvim; then nvim --headless "+Lazy! sync" +qa; fi
    if [[ -x ~/.tmux/plugins/tpm/bin/update_plugins ]]; then ~/.tmux/plugins/tpm/bin/update_plugins all || true; fi
    ./bin/migrate.sh
    if have nix-collect-garbage; then nix-collect-garbage -d; fi

install:
    ./install.sh

system:
    ./setup-system.sh

clean:
    ./bin/reclaim.sh

clean-all:
    ./bin/reclaim.sh --yes --aggressive

wallpapers query count="24":
    ./bin/wallfetch.sh "{{query}}" {{count}}

tune:
    ./bin/system-tune.sh

backup:
    ./bin/backup.sh run

gaming:
    ./bin/gaming-setup.sh

gpu:
    ./bin/gpu-setup.sh

hw:
    ./bin/hw-profile.sh

firmware:
    fwupdmgr refresh --force
    fwupdmgr update
