vim.keymap.set("n", "<leader>bd", function()
  Snacks.bufdelete()
end, { desc = "Delete buffer" })

vim.keymap.set({ "n", "x" }, "<leader>cf", function()
  LazyVim.format({ force = true })
end, { desc = "Format" })

vim.keymap.set("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit all" })
