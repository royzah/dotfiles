return {
  ---------------------------------------------------------------------------
  -- Theme: Catppuccin Mocha with full integrations
  ---------------------------------------------------------------------------
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = false,
      integrations = {
        blink_cmp = true,
        diffview = true,
        flash = true,
        gitsigns = true,
        harpoon = true,
        indent_blankline = { enabled = true },
        lsp_trouble = true,
        markdown = true,
        mason = true,
        mini = { enabled = true },
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
        neotest = true,
        noice = true,
        notify = true,
        nvim_surround = true,
        telescope = { enabled = true },
        treesitter = true,
        treesitter_context = true,
        which_key = true,
      },
    },
  },
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

  -- Illuminate (highlight other occurrences of word under cursor)
  {
    "RRethy/vim-illuminate",
    event = "BufReadPost",
    opts = {
      delay = 200,
      large_file_cutoff = 2000,
    },
  },

  ---------------------------------------------------------------------------
  -- Git
  ---------------------------------------------------------------------------

  -- Gitsigns (override LazyVim's — add inline blame)
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true,
      current_line_blame_opts = { delay = 300 },
    },
  },

  -- LazyGit
  {
    "kdheepak/lazygit.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
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
  -- Formatting (conform.nvim — format on save)
  ---------------------------------------------------------------------------
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        go = { "gofumpt", "goimports" },
        python = { "ruff_format", "ruff_organize_imports" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        javascriptreact = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        lua = { "stylua" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        terraform = { "terraform_fmt" },
        tf = { "terraform_fmt" },
        rust = { "rustfmt" },
      },
      format_on_save = {
        timeout_ms = 3000,
        lsp_fallback = true,
      },
    },
  },

  ---------------------------------------------------------------------------
  -- Linting (nvim-lint — lint on save)
  ---------------------------------------------------------------------------
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        go = { "golangcilint" },
        python = { "ruff" },
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        dockerfile = { "hadolint" },
        yaml = { "yamllint" },
        terraform = { "tflint" },
        sh = { "shellcheck" },
        bash = { "shellcheck" },
        ansible = { "ansible_lint" },
      },
    },
  },

  ---------------------------------------------------------------------------
  -- Debugging (DAP) — extras handle adapters, keep custom UI setup
  ---------------------------------------------------------------------------
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      local dapui = require("dapui")
      local dap = require("dap")

      dapui.setup()
      require("nvim-dap-virtual-text").setup()

      -- Auto open/close DAP UI
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end,
    -- stylua: ignore
    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end, desc = "Conditional Breakpoint" },
      { "<leader>dc", function() require("dap").continue() end, desc = "Continue" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
      { "<leader>do", function() require("dap").step_over() end, desc = "Step Over" },
      { "<leader>dO", function() require("dap").step_out() end, desc = "Step Out" },
      { "<leader>dr", function() require("dap").repl.open() end, desc = "Open REPL" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },
      { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = { "n", "v" } },
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
  -- Oil.nvim (edit filesystem like a buffer — press - to open)
  ---------------------------------------------------------------------------
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "Oil",
    opts = {
      default_file_explorer = false, -- don't replace neo-tree
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

  ---------------------------------------------------------------------------
  -- Todo comments (highlight TODO/FIXME/HACK + Telescope picker)
  ---------------------------------------------------------------------------
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "BufReadPost",
    opts = {},
    keys = {
      {
        "]t",
        function()
          require("todo-comments").jump_next()
        end,
        desc = "Next TODO",
      },
      {
        "[t",
        function()
          require("todo-comments").jump_prev()
        end,
        desc = "Prev TODO",
      },
      { "<leader>st", "<cmd>TodoTelescope<cr>", desc = "Search TODOs" },
    },
  },

  ---------------------------------------------------------------------------
  -- Grug-far (project-wide find and replace)
  ---------------------------------------------------------------------------
  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    keys = {
      {
        "<leader>sr",
        function()
          require("grug-far").open()
        end,
        desc = "Find and Replace (grug-far)",
      },
      {
        "<leader>sr",
        function()
          require("grug-far").with_visual_selection()
        end,
        desc = "Find and Replace (selection)",
        mode = "v",
      },
    },
    opts = {},
  },

  ---------------------------------------------------------------------------
  -- Override: disable auto-session (LazyVim has persistence.nvim)
  ---------------------------------------------------------------------------
  { "rmagatti/auto-session", enabled = false },
}
