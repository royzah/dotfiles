-- Custom keymaps (LazyVim provides most defaults)

local map = vim.keymap.set

-- Better paste (don't yank replaced text)
map("v", "p", '"_dP', { desc = "Paste without yanking" })

-- Quick save/quit
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })
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

-- Harpoon (quick file bookmarks)
map("n", "<leader>ha", function()
  require("harpoon"):list():add()
end, { desc = "Harpoon: Add file" })
map("n", "<leader>hh", function()
  local harpoon = require("harpoon")
  harpoon.ui:toggle_quick_menu(harpoon:list())
end, { desc = "Harpoon: Menu" })
map("n", "<leader>1", function()
  require("harpoon"):list():select(1)
end, { desc = "Harpoon: File 1" })
map("n", "<leader>2", function()
  require("harpoon"):list():select(2)
end, { desc = "Harpoon: File 2" })
map("n", "<leader>3", function()
  require("harpoon"):list():select(3)
end, { desc = "Harpoon: File 3" })
map("n", "<leader>4", function()
  require("harpoon"):list():select(4)
end, { desc = "Harpoon: File 4" })
map("n", "<leader>5", function()
  require("harpoon"):list():select(5)
end, { desc = "Harpoon: File 5" })

-- Oil (file manager in buffer — press - to go up)
map("n", "-", "<cmd>Oil<cr>", { desc = "Open parent directory (Oil)" })

-- Diffview
map("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", { desc = "Diffview: Open" })
map("n", "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", { desc = "Diffview: File history" })
map("n", "<leader>gH", "<cmd>DiffviewFileHistory<cr>", { desc = "Diffview: Branch history" })
map("n", "<leader>gq", "<cmd>DiffviewClose<cr>", { desc = "Diffview: Close" })

-- Neotest
map("n", "<leader>tt", function()
  require("neotest").run.run()
end, { desc = "Run nearest test" })
map("n", "<leader>tf", function()
  require("neotest").run.run(vim.fn.expand("%"))
end, { desc = "Run file tests" })
map("n", "<leader>ts", function()
  require("neotest").summary.toggle()
end, { desc = "Toggle test summary" })
map("n", "<leader>to", function()
  require("neotest").output_panel.toggle()
end, { desc = "Toggle test output" })
