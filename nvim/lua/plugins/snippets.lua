return {
  {
    "L3MON4D3/LuaSnip",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local ls = require("luasnip")
      local s = ls.snippet
      local t = ls.text_node
      local i = ls.insert_node

      -- Custom snippets
      ls.add_snippets("javascript", {
        s("cl", {
          t("console.log("),
          i(1),
          t(");"),
        }),
        s("asyncfn", {
          t("async function "),
          i(1, "functionName"),
          t("("),
          i(2),
          t(") {"),
          t({ "", "  " }),
          i(3),
          t({ "", "}" }),
        }),
      })

      ls.add_snippets("typescript", {
        s("int", {
          t("interface "),
          i(1, "InterfaceName"),
          t(" {"),
          t({ "", "  " }),
          i(2),
          t({ "", "}" }),
        }),
      })

      ls.add_snippets("python", {
        s("def", {
          t("def "),
          i(1, "function_name"),
          t("("),
          i(2),
          t("):"),
          t({ "", '    """' }),
          i(3, "Docstring"),
          t({ '"""', "    " }),
          i(4),
        }),
      })

      ls.add_snippets("go", {
        s("err", {
          t("if err != nil {"),
          t({ "", "\treturn " }),
          i(1, "err"),
          t({ "", "}" }),
        }),
      })
    end,
  },
}
