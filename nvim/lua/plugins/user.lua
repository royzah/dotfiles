return {
  ---------------------------------------------------------------------------
  -- Theme: Catppuccin Mocha
  ---------------------------------------------------------------------------
  -- LazyVim's catppuccin spec already sets undercurls and plugin integrations
  { "catppuccin/nvim", name = "catppuccin", opts = { flavour = "mocha" } },
  { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin-mocha" } },

  ---------------------------------------------------------------------------
  -- Navigation & Editing
  ---------------------------------------------------------------------------

  -- Tmux navigation (Ctrl-h/j/k/l across tmux + nvim panes)
  { "christoomey/vim-tmux-navigator", lazy = false },

  -- Better escape (jk to exit insert mode)
  { "max397574/better-escape.nvim", event = "InsertEnter", opts = {} },

  -- Treesitter context (sticky function header at top of screen)
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "BufReadPost",
    opts = {
      max_lines = 3,
      min_window_height = 20,
    },
    keys = {
      { "<leader>ut", "<cmd>TSContextToggle<cr>", desc = "Toggle Treesitter Context" },
    },
  },

  ---------------------------------------------------------------------------
  -- Git
  ---------------------------------------------------------------------------

  -- Gitsigns: add inline blame to LazyVim's setup
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true,
      current_line_blame_opts = { delay = 300 },
    },
  },

  -- Fugitive (Git commands inside neovim: :Git blame, :Git log, :Gvdiffsplit)
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "Gvdiffsplit", "Gread", "Gwrite" },
    keys = {
      { "<leader>gB", "<cmd>Git blame<cr>", desc = "Git Blame (Fugitive)" },
      { "<leader>gD", "<cmd>Gvdiffsplit<cr>", desc = "Git Diff Split" },
      { "<leader>gl", "<cmd>Git log --oneline<cr>", desc = "Git Log" },
    },
  },

  ---------------------------------------------------------------------------
  -- Formatting: LazyVim formats on save; extras cover go/ts/rust/terraform/c
  ---------------------------------------------------------------------------
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "ruff_format", "ruff_organize_imports" },
        nix = { "alejandra" },
      },
    },
  },

  ---------------------------------------------------------------------------
  -- Linting: extras and LSPs cover go/python/js/docker; these fill the gaps
  ---------------------------------------------------------------------------
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        yaml = { "yamllint" },
        terraform = { "tflint" },
        sh = { "shellcheck" },
        bash = { "shellcheck" },
        ansible = { "ansible_lint" },
      },
    },
  },

  ---------------------------------------------------------------------------
  -- Debugging: dap.core extra owns setup; o/O swapped to match most debuggers
  ---------------------------------------------------------------------------
  {
    "mfussenegger/nvim-dap",
    -- stylua: ignore
    keys = {
      { "<leader>do", function() require("dap").step_over() end, desc = "Step Over" },
      { "<leader>dO", function() require("dap").step_out() end, desc = "Step Out" },
    },
  },

  ---------------------------------------------------------------------------
  -- Tools
  ---------------------------------------------------------------------------

  -- Database client
  {
    "tpope/vim-dadbod",
    dependencies = {
      "kristijanhusak/vim-dadbod-ui",
      "kristijanhusak/vim-dadbod-completion",
    },
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection" },
    keys = {
      { "<leader>D", "<cmd>DBUIToggle<cr>", desc = "Toggle DB UI" },
    },
  },

  -- Markdown preview in browser
  {
    "iamcco/markdown-preview.nvim",
    build = "cd app && npm install",
    ft = { "markdown" },
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown Preview" },
    },
  },

  -- Colorizer (show hex colors inline)
  { "NvChad/nvim-colorizer.lua", event = "BufReadPost", opts = {} },

  -- Better quickfix
  { "kevinhwang91/nvim-bqf", ft = "qf" },

  -- Floating terminal
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      size = 20,
      open_mapping = [[<c-\>]],
      direction = "float",
      float_opts = { border = "curved" },
    },
  },

  -- Zen mode (distraction-free coding)
  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    keys = {
      { "<leader>z", "<cmd>ZenMode<cr>", desc = "Zen Mode" },
    },
    opts = {
      window = { width = 120 },
    },
  },

  ---------------------------------------------------------------------------
  -- Git: Diffview (side-by-side diffs, file history)
  ---------------------------------------------------------------------------
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
    opts = {
      enhanced_diff_hl = true,
      view = {
        default = { layout = "diff2_horizontal" },
      },
    },
  },

  ---------------------------------------------------------------------------
  -- Oil.nvim (edit filesystem like a buffer; press - to open)
  ---------------------------------------------------------------------------
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "Oil",
    opts = {
      default_file_explorer = false, -- the snacks explorer stays the default
      view_options = { show_hidden = true },
      float = {
        padding = 2,
        max_width = 120,
        max_height = 30,
      },
    },
  },

  ---------------------------------------------------------------------------
  -- Undo tree (visual undo history)
  ---------------------------------------------------------------------------
  {
    "mbbill/undotree",
    keys = {
      { "<leader>U", "<cmd>UndotreeToggle<cr>", desc = "Toggle Undotree" },
    },
  },
}
