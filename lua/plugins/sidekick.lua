---@type LazySpec
return {
  "folke/sidekick.nvim",
  opts = {
    cli = {
      tools = {
        -- Windows: `opencode` resolves to the npx .CMD shim, which sidekick
        -- can't launch. Point it at the scoop shim instead.
        opencode = { cmd = { "opencode.exe" } },
      },
    },
  },
}
