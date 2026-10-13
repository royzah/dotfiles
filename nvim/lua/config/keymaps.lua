-- Custom keymaps (LazyVim provides most defaults)

local map = vim.keymap.set

-- Better paste (don't yank replaced text)
map("v", "p", '"_dP', { desc = "Paste without yanking" })

-- Quit all (save is LazyVim's <C-s>; <leader>w is its windows group)
map("n", "<leader>Q", "<cmd>qa<cr>", { desc = "Quit all" })

-- Center cursor when scrolling/searching
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up (centered)" })
map("n", "n", "nzzzv", { desc = "Next match (centered)" })
map("n", "N", "Nzzzv", { desc = "Prev match (centered)" })

-- Paste from system clipboard in insert/command mode (Ctrl+Shift+V)
map("i", "<C-S-v>", "<C-r>+", { desc = "Paste from clipboard" })
map("c", "<C-S-v>", "<C-r>+", { desc = "Paste from clipboard" })

-- Terminal
map("t", "<Esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

-- Oil (file manager in buffer; press - to go up)
map("n", "-", "<cmd>Oil<cr>", { desc = "Open parent directory (Oil)" })

-- Diffview
map("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", { desc = "Diffview: Open" })
map("n", "<leader>gF", "<cmd>DiffviewFileHistory %<cr>", { desc = "Diffview: File history" })
map("n", "<leader>gH", "<cmd>DiffviewFileHistory<cr>", { desc = "Diffview: Branch history" })
map("n", "<leader>gq", "<cmd>DiffviewClose<cr>", { desc = "Diffview: Close" })
