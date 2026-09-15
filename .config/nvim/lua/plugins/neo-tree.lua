return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    keys = {
      {
        "<leader>e",
        function()
          require("config.global_explorer").toggle()
        end,
        desc = "Toggle Explorer (All Tabs)",
      },
      {
        "<leader>E",
        function()
          require("config.global_explorer").toggle()
        end,
        desc = "Toggle Explorer (All Tabs)",
      },
    },
    opts = {
      git_status_scope_to_path = true,
      filesystem = {
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
        filtered_items = {
          hide_dotfiles = false,
          -- Hiding ignored files blocks the first render on a repository-wide scan.
          hide_gitignored = false,
        },
        window = {
          mappings = {
            q = function()
              require("config.global_explorer").close_all()
            end,
          },
        },
      },
      default_component_configs = {
        indent = {
          with_expanders = false,
          expander_collapsed = ">",
          expander_expanded = "v",
        },
        icon = {
          folder_closed = "▸",
          folder_open = "▾",
          folder_empty = "▸",
          folder_empty_open = "▾",
          default = "",
          provider = function(icon, node)
            if node.type == "file" or node.type == "terminal" then
              icon.text = ""
            end
          end,
        },
        modified = { symbol = "[+] " },
        git_status = {
          symbols = {
            added = "+",
            deleted = "-",
            modified = "M",
            renamed = "R",
            untracked = "U",
            ignored = "I",
            unstaged = "W",
            staged = "S",
            conflict = "C",
          },
        },
      },
    },
  },
}
