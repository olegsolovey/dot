vim.keymap.set("n", "<leader>bd", function()
  Snacks.bufdelete()
end, { desc = "Delete buffer" })

vim.keymap.set({ "n", "x" }, "<leader>cf", function()
  LazyVim.format({ force = true })
end, { desc = "Format" })

vim.keymap.set("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit all" })

-- Remove LazyVim's Alt+j/Alt+k "move line" mappings
for _, key in ipairs({ "<A-j>", "<A-k>" }) do
  pcall(vim.keymap.del, { "n", "i", "v" }, key)
end
