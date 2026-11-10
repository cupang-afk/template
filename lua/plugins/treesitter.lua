-- Customize Treesitter
-- --------------------
-- Treesitter customizations are handled with AstroCore
-- as nvim-treesitter simply provides a download utility for parsers
-- https://docs.astronvim.com/recipes/treesitter

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    treesitter = {
      highlight = true, -- enable/disable treesitter based highlighting
      indent = true, -- enable/disable treesitter based indentation
      auto_install = true, -- enable/disable automatic installation of detected languages
      ensure_installed = {
        "lua",
        "vim",
        "javascript", -- js / jsx
        "typescript", -- ts
        "tsx", -- react
        "python",
        "vue",
        "toml",
        "yaml",
      },
    },
  },
}
