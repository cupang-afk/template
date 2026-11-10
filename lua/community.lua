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
  { import = "astrocommunity.ai.minuet-ai-nvim" },
  {
    "milanglacier/minuet-ai.nvim",
    opts = {
      provider = "codestral",
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
          accept = "<M-l>",
          accept_line = "<M-j>",
          accept_n_lines = "<M-z>",
          prev = "<M-[>",
          next = "<M-]>",
          dismiss = "<M-e>",
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
