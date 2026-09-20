-- DAP adapter configurations
-- LazyVim extras handle basic Go/Python/JS setup.
-- This file adds extra launch configurations.

return {
  {
    "mfussenegger/nvim-dap",
    opts = function()
      local dap = require("dap")

      -- Go: add "Debug test" and "Debug package" configs
      dap.configurations.go = dap.configurations.go or {}
      table.insert(dap.configurations.go, {
        type = "go",
        name = "Debug test (file)",
        request = "launch",
        mode = "test",
        program = "${file}",
      })
      table.insert(dap.configurations.go, {
        type = "go",
        name = "Debug package",
        request = "launch",
        program = "${fileDirname}",
      })

      -- Python: auto-detect virtualenv
      dap.configurations.python = dap.configurations.python or {}
      table.insert(dap.configurations.python, {
        type = "python",
        request = "launch",
        name = "Launch file (auto venv)",
        program = "${file}",
        pythonPath = function()
          local venv = os.getenv("VIRTUAL_ENV")
          if venv then
            return venv .. "/bin/python"
          end
          if vim.fn.filereadable(".venv/bin/python") == 1 then
            return ".venv/bin/python"
          end
          return "python3"
        end,
      })

      -- JS/TS: attach to running process
      if not dap.configurations.javascript then
        dap.configurations.javascript = {}
      end
      table.insert(dap.configurations.javascript, {
        type = "pwa-node",
        request = "attach",
        name = "Attach to process",
        processId = require("dap.utils").pick_process,
        cwd = "${workspaceFolder}",
      })
      dap.configurations.typescript = dap.configurations.javascript
    end,
  },
}
