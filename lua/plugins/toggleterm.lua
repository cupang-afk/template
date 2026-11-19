-- Choose the shell for Neovim and toggleterm.
-- Candidates are ordered from high to low priority for each OS.
-- PowerShell flags follow `:help shell-powershell` and `:help shell-pwsh`.
local is_windows = vim.fn.has "win32" == 1

---@param candidates string[]
---@return string?
local function first_executable(candidates)
  for _, candidate in ipairs(candidates) do
    if candidate and candidate ~= "" and vim.fn.executable(candidate) == 1 then return candidate end
  end
end

local shell
if is_windows then
  shell = first_executable { "pwsh", "powershell", "cmd" }
else
  local candidates = { vim.env.SHELL }
  if vim.fn.has "mac" == 1 then
    vim.list_extend(candidates, { "zsh", "bash", "sh" })
  else
    vim.list_extend(candidates, { "zsh", "fish", "bash", "sh" })
  end
  shell = first_executable(candidates)
end

if not shell then return {} end

vim.opt.shell = shell

if is_windows and (shell == "pwsh" or shell == "powershell") then
  local flags = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command "
    .. "[Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new();"
    .. "$PSDefaultParameterValues['Out-File:Encoding']='utf8';"
  if shell == "pwsh" then flags = flags .. "$PSStyle.OutputRendering = 'PlainText';" end
  vim.opt.shellcmdflag = flags
  vim.opt.shellredir = "-RedirectStandardOutput %s -NoNewWindow -Wait"
  vim.opt.shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
  vim.opt.shelltemp = false
  if shell == "pwsh" then vim.env.__SuppressAnsiEscapeSequences = "1" end
elseif is_windows then
  -- Restore the Windows defaults when cmd wins the priority list.
  vim.opt.shellcmdflag = "/s /c"
  vim.opt.shellredir = ">%s 2>&1"
  vim.opt.shellpipe = "2>&1| tee"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = '"'
  vim.opt.shelltemp = false
end

---@type LazySpec
return {
  {
    "akinsho/toggleterm.nvim",
    opts = { shell = shell },
  },
}
