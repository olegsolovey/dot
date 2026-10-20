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

-- The builtin editorconfig hook runs on BufReadPost after FileType, so apply on the next tick
-- to override repo .editorconfig indent (matches the shfmt -i 2 override in plugins/languages.lua).
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("user_sh", { clear = true }),
  pattern = { "sh", "bash", "zsh" },
  callback = function(event)
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(event.buf) then
        return
      end
      vim.bo[event.buf].expandtab = true
      vim.bo[event.buf].shiftwidth = 2
      vim.bo[event.buf].tabstop = 2
      vim.bo[event.buf].softtabstop = 2
    end)
  end,
})
