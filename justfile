set shell := ["bash", "-cu"]

default:
    @just --list

lint:
    shellcheck -x bootstrap.sh bootstrap-user.sh install.sh setup-system.sh bin/*.sh claude/statusline.sh claude/hooks/*.sh
    shfmt -d bootstrap.sh bootstrap-user.sh install.sh setup-system.sh bin/ claude/
    zsh -n zshrc
    luacheck nvim/ --quiet
    stylua --check nvim/
    markdownlint README.md NVIM_GUIDE.md TMUX_GUIDE.md WINDOWS_GUIDE.md CLAUDE.md AGENTS.md GEMINI.md .github/copilot-instructions.md templates/CLAUDE.md templates/AGENTS.md templates/GEMINI.md templates/.github/copilot-instructions.md claude/CLAUDE.md
    jq empty claude/settings.json nvim/lazyvim.json

fmt:
    shfmt -w bootstrap.sh bootstrap-user.sh install.sh setup-system.sh bin/ claude/
    stylua nvim/

# Update everything - system, CLI tools, runtimes, editor, AI. Run monthly.
update:
    sudo apt update && sudo apt upgrade -y
    brew update && brew upgrade
    mise upgrade
    rustup update
    claude update
    nvim --headless "+Lazy! sync" +qa
    -~/.tmux/plugins/tpm/bin/update_plugins all
    ./bin/migrate.sh
    nix-collect-garbage -d

install:
    ./install.sh

system:
    ./setup-system.sh

nvim:
    mkdir -p ~/.config/nvim/lua/config ~/.config/nvim/lua/plugins
    ln -sfn "$(pwd)/nvim/init.lua" ~/.config/nvim/init.lua
    ln -sfn "$(pwd)/nvim/lazyvim.json" ~/.config/nvim/lazyvim.json
    ln -sfn "$(pwd)/nvim/stylua.toml" ~/.config/nvim/stylua.toml
    ln -sfn "$(pwd)/nvim/lua/config/lazy.lua" ~/.config/nvim/lua/config/lazy.lua
    ln -sfn "$(pwd)/nvim/lua/config/options.lua" ~/.config/nvim/lua/config/options.lua
    ln -sfn "$(pwd)/nvim/lua/config/keymaps.lua" ~/.config/nvim/lua/config/keymaps.lua
    ln -sfn "$(pwd)/nvim/lua/config/autocmds.lua" ~/.config/nvim/lua/config/autocmds.lua
    ln -sfn "$(pwd)/nvim/lua/plugins/user.lua" ~/.config/nvim/lua/plugins/user.lua
    ln -sfn "$(pwd)/nvim/lua/plugins/lsp.lua" ~/.config/nvim/lua/plugins/lsp.lua
    ln -sfn "$(pwd)/nvim/lua/plugins/dap-config.lua" ~/.config/nvim/lua/plugins/dap-config.lua
    ln -sfn "$(pwd)/nvim/lua/plugins/snippets.lua" ~/.config/nvim/lua/plugins/snippets.lua
    ln -sfn "$(pwd)/nvim/lua/plugins/claudecode.lua" ~/.config/nvim/lua/plugins/claudecode.lua

git:
    ln -sfn "$(pwd)/gitconfig" ~/.gitconfig
    ln -sfn "$(pwd)/gitignore_global" ~/.gitignore_global

ssh:
    mkdir -p ~/.ssh/sockets
    chmod 700 ~/.ssh
    ln -sfn "$(pwd)/ssh_config" ~/.ssh/config
    chmod 600 ~/.ssh/config

zsh:
    ln -sfn "$(pwd)/zshrc" ~/.zshrc
    ln -sfn "$(pwd)/starship/starship.toml" ~/.config/starship.toml

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
