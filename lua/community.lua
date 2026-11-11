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
      provider = "openai_fim_compatible",
      n_completions = 1,
      throttle = 200,
      debounce = 150,
      provider_options = {
        openai_fim_compatible = {
          model = "gkd 1.5b production production distilled rerun no denoise v2|Q8_0|1537269856",
          end_point = "http://127.0.0.1:6996/v1/completions",
          api_key = function() return "dummy" end,
          name = "TurboLLM",
          stream = true,
          optional = {
            max_tokens = 256,
            stop = { "<|file_sep|>", "<|endoftext|>", "\n\n" },
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
  { import = "astrocommunity.git.diffview-nvim" },
  { import = "astrocommunity.icon.mini-icons" },
  { import = "astrocommunity.editing-support.treesj" },
  { import = "astrocommunity.search.grug-far-nvim" },
  { import = "astrocommunity.split-and-window.minimap-vim" },
  -- import/override with your plugins folder
}
