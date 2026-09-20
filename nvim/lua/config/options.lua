-- Options are automatically loaded before lazy.nvim startup
-- LazyVim already sets: number, relativenumber, expandtab, smartindent,
-- ignorecase, smartcase, termguicolors, signcolumn, splitright, splitbelow,
-- clipboard, mouse, undofile, and leader = space.
-- Only override or add what differs from LazyVim defaults here.

local opt = vim.opt

-- Tabs (LazyVim defaults to 2, which is fine for most — Go uses gofumpt anyway)
opt.tabstop = 2
opt.shiftwidth = 2

-- Search: don't keep highlighting after search
opt.hlsearch = false

-- Appearance
opt.colorcolumn = "120"
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.cursorline = true
opt.wrap = false

-- Backup: use persistent undo, no swap
opt.swapfile = false
opt.backup = false
opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.fn.mkdir(vim.opt.undodir:get()[1], "p")

-- Performance
opt.updatetime = 200
opt.timeoutlen = 300

-- Folding via treesitter
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldenable = false
