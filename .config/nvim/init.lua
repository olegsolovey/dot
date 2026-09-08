vim.g.mapleader = " "
vim.g.maplocalleader = " "

local function readable_molokai_highlights()
  vim.api.nvim_set_hl(0, "Comment", { fg = "#B0B8BA", ctermfg = 250 })
  vim.api.nvim_set_hl(0, "@comment", { link = "Comment" })
  vim.api.nvim_set_hl(0, "@comment.documentation", { link = "Comment" })
  vim.api.nvim_set_hl(0, "@lsp.type.comment", { link = "Comment" })

  -- molokai only sets Visual's background and inherits Neovim's default ctermfg=0,
  -- which renders black-on-dark-grey. Keep the text color and use a visible background.
  vim.api.nvim_set_hl(0, "Visual", { bg = "#403D3D", ctermbg = 238 })
  vim.api.nvim_set_hl(0, "VisualNOS", { link = "Visual" })
end

local colors_group = vim.api.nvim_create_augroup("readable_molokai_highlights", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", {
  group = colors_group,
  pattern = "molokai",
  callback = readable_molokai_highlights,
})

require("config.lazy")
