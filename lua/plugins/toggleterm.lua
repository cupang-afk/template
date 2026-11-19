-- Choose the shell for toggleterm only.
-- Candidates are ordered from high to low priority for each OS.
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

---@type LazySpec
return {
  {
    "akinsho/toggleterm.nvim",
    opts = { shell = shell },
  },
}
