---@type LazySpec
return {
  "cursortab/cursortab.nvim",
  build = "cd server && go build",
  lazy = false,
  config = function()
    require("cursortab").setup {
      keymaps = {
        -- recipes.ai wires blink's <Tab> to vim.g.ai_accept below, so
        -- cursortab must not also grab <Tab>.
        accept = false,
        -- Blink owns <S-Tab> and cursortab does not expose partial accept.
        partial_accept = false,
      },
      provider = {
        type = "sweep",
        url = "http://127.0.0.1:6996",
        model = "Gkd 1.5B Production Production Distilled Rerun No Denoise v2",
        temperature = 0,
        max_tokens = 4092,
        context_size = 32768,
      },
    }
  end,
  specs = {
    {
      "AstroNvim/astrocore",
      opts = {
        options = {
          g = {
            ai_accept = function()
              return require("cursortab").accept()
            end,
          },
        },
        mappings = {
          n = {
            -- Keep <Tab> in normal mode for cursortab's cursor-prediction jumps.
            ["<Tab>"] = {
              function() require("cursortab").accept() end,
              desc = "Cursortab: accept/jump",
            },
          },
        },
      },
    },
  },
}
