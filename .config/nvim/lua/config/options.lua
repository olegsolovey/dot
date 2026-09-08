vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.lazyvim_python_lsp = "basedpyright"
vim.g.lazyvim_python_ruff = "ruff"
vim.g.lazyvim_rust_diagnostics = "rust-analyzer"

vim.g.root_spec = {
  "lsp",
  {
    "MODULE.bazel",
    "WORKSPACE.bazel",
    "WORKSPACE",
    "Cargo.toml",
    "pyproject.toml",
    "CMakePresets.json",
    "CMakeLists.txt",
    "compile_commands.json",
    ".git",
  },
  "cwd",
}

local opt = vim.opt
opt.background = "dark"
opt.termguicolors = false
opt.cmdheight = 1
opt.colorcolumn = "100"
opt.number = true
opt.relativenumber = false
opt.list = true
opt.listchars = {
  eol = "¬",
  space = "·",
  tab = "-▸",
  trail = "·",
}
opt.fillchars:append({
  foldopen = "v",
  foldclose = ">",
})
opt.scrolloff = 6
opt.sidescrolloff = 8
opt.wrap = false
