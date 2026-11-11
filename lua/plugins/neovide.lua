if not vim.g.neovide then return {} end

-- Single-instance IPC: per-instance pipe + active window tracker
local pid = vim.fn.getpid()
local instance_pipe = string.format([[\\.\pipe\neovide_%d]], pid)
pcall(vim.fn.serverstart, instance_pipe)
pcall(vim.fn.serverstart, [[\\.\pipe\neovide]])

local active_file = (vim.env.TEMP or "C:\\Windows\\Temp") .. [[\neovide_active.pipe]]
local function mark_active()
  local f = io.open(active_file, "w")
  if f then
    f:write(instance_pipe)
    f:close()
  end
end
mark_active()

vim.api.nvim_create_autocmd("FocusGained", {
  desc = "Track most recently focused Neovide instance for launcher",
  callback = mark_active,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  desc = "Clear active Neovide pipe on exit",
  callback = function()
    local f = io.open(active_file, "r")
    if f then
      local cur = f:read("*all")
      f:close()
      if cur == instance_pipe then
        os.remove(active_file)
      end
    end
  end,
})

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
