if not vim.g.neovide then return {} end

-- Start named pipe server for single-instance launcher tab-reuse
pcall(vim.fn.serverstart, [[\\.\pipe\neovide]])

---@type LazySpec
return {
  "astrocore",
  ---@type AstroCoreOpts
  opts = {
    options = {
      opt = {
        guifont = "CaskaydiaCove Nerd Font:h10",
      },
    },
    autocmds = {
      neovide_titlebar_colorscheme = {
        {
          event = "ColorScheme",
          desc = "Sync Neovide Windows titlebar background with StatusLine",
          callback = function()
            local hl = vim.api.nvim_get_hl(0, { name = "StatusLine" })
            if hl and hl.bg then
              vim.g.neovide_title_background_color = string.format("#%06x", hl.bg)
            end
            if hl and hl.fg then
              vim.g.neovide_title_text_color = string.format("#%06x", hl.fg)
            end
          end,
        },
      },
    },
  },
}
