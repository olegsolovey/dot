-- The markdown extra renders tables, headings and code blocks in the buffer
-- (render-markdown.nvim, toggle with <leader>um) and previews in a browser
-- (markdown-preview.nvim, <leader>cp). Its markdownlint-cli2, markdown-toc and
-- prettier tools need npm, which the install scripts do not provide, so they are
-- dropped here.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- marksman roots at .git and indexes every markdown file below it, then
        -- publishes diagnostics for all of them. In a monorepo with tens of
        -- thousands of markdown files that pins a CPU core and grows Neovim to
        -- gigabytes, so it stays off.
        marksman = { enabled = false },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = vim.tbl_filter(function(tool)
        return tool ~= "markdownlint-cli2" and tool ~= "markdown-toc"
      end, opts.ensure_installed or {})
    end,
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      opts.linters_by_ft.markdown = nil
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft.markdown = nil
      opts.formatters_by_ft["markdown.mdx"] = nil
    end,
  },
}
