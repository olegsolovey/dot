return {
  {
    "folke/snacks.nvim",
    opts = {
      indent = {
        animate = { enabled = false },
        -- snacks.scope debounces scope detection (default 30ms); 0 redraws immediately
        scope = { debounce = 0 },
      },
    },
  },
}
