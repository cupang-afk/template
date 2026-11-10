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
  { "AstroNvim/astroui", opts = { colorscheme = "catppuccin" } },
  { import = "astrocommunity.completion.blink-cmp" },
  { "saghen/blink.compat", version = "^2", lazy = true, opts = {} },
  { import = "astrocommunity.completion.supermaven-nvim" },
  { import = "astrocommunity.scrolling.nvim-scrollbar" },
  { import = "astrocommunity.editing-support.wildfire-nvim" },
  { import = "astrocommunity.editing-support.nvim-treesitter-context" },
  -- import/override with your plugins folder
}
