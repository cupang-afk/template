local is_windows = vim.fn.has("win32") == 1
local opencode_cmd = is_windows and "opencode.exe" or "opencode"

---@type LazySpec
return {
  "folke/sidekick.nvim",
  opts = {
    cli = {
      -- Keep sessions in Neovim terminals. Windows `tmux` is a psmux alias,
      -- and MSYS tmux cannot be driven reliably from Neovim.
      mux = { enabled = false },
      tools = {
        -- Windows: `opencode` resolves to the npx .CMD shim, which sidekick
        -- can't launch. Use the scoop .exe shim there. macOS and Linux use
        -- the `opencode` binary on PATH.
        opencode = { cmd = { opencode_cmd } },
        -- OpenCode 2 uses the same `opencode` command as OpenCode 1.
        -- This adds a second name for the same binary.
        opencode2 = {
          cmd = { opencode_cmd, "--standalone" },
          env = {}, -- v2 reads cli.json for theme settings, not OPENCODE_THEME
          is_proc = "\\<opencode\\>",
          url = "https://opencode.ai/v2/",
          continue = { "--continue" },
          native_scroll = true,
          keys = {
            prompt = { "<a-p>", "prompt" },
          },
        },
      },
    },
  },
}
