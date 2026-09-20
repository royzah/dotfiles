-- LSP server overrides
-- Base configs are handled by LazyVim extras (go, python, rust, typescript, etc.)
-- Only add server-specific settings or servers not covered by extras here.

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- TypeScript: inlay hints (vtsls is LazyVim's default TS server)
        vtsls = {
          settings = {
            typescript = {
              inlayHints = {
                parameterNames = { enabled = "all" },
                parameterTypes = { enabled = true },
                variableTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                enumMemberValues = { enabled = true },
              },
            },
            javascript = {
              inlayHints = {
                parameterNames = { enabled = "all" },
                parameterTypes = { enabled = true },
                variableTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                enumMemberValues = { enabled = true },
              },
            },
          },
        },

        -- Go: enable all analyses + staticcheck
        gopls = {
          settings = {
            gopls = {
              gofumpt = true,
              analyses = {
                unusedparams = true,
                shadow = true,
                nilness = true,
                unusedwrite = true,
                useany = true,
              },
              staticcheck = true,
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                compositeLiteralTypes = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
              },
            },
          },
        },

        -- YAML: schema support for GitHub Actions + Ansible + k8s
        yamlls = {
          settings = {
            yaml = {
              schemas = {
                ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
                ["https://json.schemastore.org/kustomization.json"] = "kustomization.yaml",
                kubernetes = "/*.k8s.yaml",
              },
            },
          },
        },

        -- Servers not covered by extras
        ansiblels = {},
        tailwindcss = {},
        html = {},
        cssls = {},
      },
    },
  },

  -- Mason: ensure additional tools are installed
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        -- Formatters
        "prettier",
        "ruff",
        "black",
        "isort",
        "gofumpt",
        "goimports",
        "stylua",
        "shfmt",

        -- Linters
        "eslint_d",
        "golangci-lint",
        "shellcheck",
        "hadolint",
        "yamllint",
        "ansible-lint",
        "tflint",

        -- DAP
        "debugpy",
        "delve",
        "js-debug-adapter",
      },
    },
  },
}
