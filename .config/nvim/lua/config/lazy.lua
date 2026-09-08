local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    version = false,
  },
  install = { colorscheme = { "carbonfox", "habamax" } },
  checker = {
    enabled = true,
    notify = false,
  },
  ui = {
    icons = {
      cmd = ": ",
      config = "cfg ",
      debug = "D ",
      event = "evt ",
      favorite = "* ",
      ft = "ft ",
      init = "init ",
      import = "imp ",
      keys = "key ",
      lazy = "lazy ",
      loaded = "+",
      not_loaded = "-",
      plugin = "plug ",
      runtime = "rt ",
      require = "req ",
      source = "src ",
      start = "> ",
      task = "ok ",
      list = { "*", ">", "+", "-" },
    },
  },
  change_detection = { notify = false },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "zipPlugin",
      },
    },
  },
})
