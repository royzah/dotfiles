-- Autocmds are automatically loaded on the VeryLazy event
-- LazyVim already provides: highlight on yank, resize splits, last location,
-- close with q, auto create dir. Only add custom ones here.

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- Python: 4-space indent
autocmd("FileType", {
  group = augroup("filetype_python", { clear = true }),
  pattern = { "python" },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})

-- Go: tabs, not spaces
autocmd("FileType", {
  group = augroup("filetype_go", { clear = true }),
  pattern = { "go" },
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})

-- Remove trailing whitespace on save
autocmd("BufWritePre", {
  group = augroup("remove_trailing_whitespace", { clear = true }),
  pattern = "*",
  callback = function()
    local save_cursor = vim.fn.getpos(".")
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.setpos(".", save_cursor)
  end,
})

-- Terminal: no line numbers, start in insert
autocmd("TermOpen", {
  group = augroup("terminal_settings", { clear = true }),
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.cmd("startinsert")
  end,
})
