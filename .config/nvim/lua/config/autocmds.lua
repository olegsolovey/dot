local cuda_group = vim.api.nvim_create_augroup("user_cuda", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = cuda_group,
  pattern = "cuda",
  callback = function(event)
    vim.bo[event.buf].commentstring = "// %s"
    vim.bo[event.buf].shiftwidth = 2
    vim.bo[event.buf].tabstop = 2
  end,
})
