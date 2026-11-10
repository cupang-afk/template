-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.pack.lua" },
  { import = "astrocommunity.utility.noice-nvim" },
  { import = "astrocommunity.diagnostics.trouble-nvim" },
  { import = "astrocommunity.motion.flash-nvim" },
  { import = "astrocommunity.editing-support.yanky-nvim" },
  { import = "astrocommunity.motion.nvim-surround" },
  { import = "astrocommunity.colorscheme.catppuccin" },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      flavour = "mocha",
      auto_integrations = false,
      integrations = {
        aerial = true,
        blink_cmp = { style = "bordered" },
        colorful_winsep = { color = "lavender" },
        dap = true,
        dap_ui = true,
        flash = true,
        gitsigns = true,
        lsp_trouble = true,
        mason = true,
        mini = { indentscope_color = "lavender" },
        neotree = true,
        noice = true,
        notifier = true,
        nvim_surround = true,
        snacks = { indent_scope_color = "lavender" },
        treesitter_context = true,
        which_key = true,
        window_picker = true,
      },
    },
  },
  { "AstroNvim/astroui", opts = { colorscheme = "catppuccin-nvim" } },
  { import = "astrocommunity.completion.blink-cmp" },
  { "saghen/blink.compat", version = "^2", lazy = true, opts = {} },
  { import = "astrocommunity.scrolling.nvim-scrollbar" },
  { import = "astrocommunity.editing-support.wildfire-nvim" },
  { import = "astrocommunity.editing-support.nvim-treesitter-context" },
  { import = "astrocommunity.comment.ts-comments-nvim" },
  { import = "astrocommunity.ai.sidekick-nvim" },
  { import = "astrocommunity.recipes.ai" },
  { import = "astrocommunity.ai.minuet-ai-nvim" },
  {
    "milanglacier/minuet-ai.nvim",
    opts = {
      provider = "codestral",
      n_completions = 1, -- single request per trigger; prevents instant 429 on free tier
      throttle = 1500, -- 1.5s between requests; keeps under Mistral 1 RPS limit
      debounce = 600, -- wait 600ms after typing stops before firing
      provider_options = {
        codestral = {
          model = "codestral-2508",
          end_point = "https://api.mistral.ai/v1/fim/completions",
          api_key = "MISTRAL_KEY",
          optional = {
            max_tokens = 256,
            stop = { "\n\n" },
          },
        },
      },
      virtualtext = {
        auto_trigger_ft = { "*" },
        keymap = {
          accept = false, -- handled by recipes.ai (<Tab>)
          accept_line = nil,
          accept_n_lines = nil,
          prev = nil,
          next = nil,
          dismiss = nil,
        },
      },
    },
    specs = {
      {
        "AstroNvim/astrocore",
        opts = {
          options = {
            g = {
              ai_accept = function()
                local vt = require "minuet.virtualtext"
                if vt.action.is_visible() then
                  vt.action.accept()
                  return true
                end
              end,
            },
          },
        },
      },
    },
  },
  { import = "astrocommunity.split-and-window.colorful-winsep-nvim" },
  { import = "astrocommunity.recipes.vscode-icons" },
  { import = "astrocommunity.neovim-lua-development.helpview-nvim" },
  { import = "astrocommunity.diagnostics.tiny-inline-diagnostic-nvim" },
  { import = "astrocommunity.recipes.heirline-vscode-winbar" },
  { import = "astrocommunity.recipes.neovide" },
  { import = "astrocommunity.recipes.cache-colorscheme" },
  -- import/override with your plugins folder
}
