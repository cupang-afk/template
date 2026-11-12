if not vim.g.neovide then return {} end

-- Cross-platform single-instance IPC: per-instance server + active window tracker
local is_windows = vim.fn.has("win32") == 1

local function state_dir()
  if is_windows then
    return vim.env.TMP or vim.env.TEMP or "C:\\Windows\\Temp"
  end
  -- $XDG_RUNTIME_DIR (/run/user/<uid>) is per-user and mode 0700, so it needs
  -- no administrator rights and keeps the socket out of world-writable /tmp.
  for _, dir in ipairs({ vim.env.XDG_RUNTIME_DIR, vim.env.TMPDIR, "/tmp" }) do
    if dir and dir ~= "" and vim.fn.isdirectory(dir) == 1 and vim.fn.filewritable(dir) == 1 then
      return dir
    end
  end
  return "/tmp"
end

local tmp = state_dir():gsub("[/\\]+$", "")

local pid = vim.fn.getpid()
local instance_pipe, fallback_pipe
if is_windows then
  instance_pipe = string.format([[\\.\pipe\neovide_%d]], pid)
  fallback_pipe = [[\\.\pipe\neovide]]
else
  instance_pipe = string.format("%s/neovide_%d.sock", tmp, pid)
  fallback_pipe = string.format("%s/neovide.sock", tmp)
end

pcall(vim.fn.serverstart, instance_pipe)
pcall(vim.fn.serverstart, fallback_pipe)

local active_file = string.format("%s/neovide_active.pipe", tmp)
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
  desc = "Clear active Neovide server on exit",
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
      g = {
        neovide_floating_shadow = false,
      },
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
