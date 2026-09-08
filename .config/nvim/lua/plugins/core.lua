local kinds = {
  Array = "[] ",
  Boolean = "B ",
  Class = "C ",
  Codeium = "AI ",
  Color = "# ",
  Collapsed = "> ",
  Constant = "K ",
  Constructor = "new ",
  Control = "ctl ",
  Copilot = "AI ",
  Enum = "E ",
  EnumMember = "e ",
  Event = "ev ",
  Field = ". ",
  File = "file ",
  Folder = "dir ",
  Function = "fn ",
  Interface = "I ",
  Key = "key ",
  Keyword = "kw ",
  Method = "m ",
  Module = "mod ",
  Namespace = "ns ",
  Null = "nil ",
  Number = "N ",
  Object = "obj ",
  Operator = "op ",
  Package = "pkg ",
  Property = "p ",
  Reference = "& ",
  Snippet = "snip ",
  String = "S ",
  Struct = "struct ",
  Supermaven = "AI ",
  TabNine = "AI ",
  Text = "txt ",
  TypeParameter = "T ",
  Unit = "unit ",
  Value = "val ",
  Variable = "v ",
}

return {
  {
    "EdenEast/nightfox.nvim",
    lazy = false,
    priority = 1000,
  },
  -- kept installed so `:colorscheme molokai` still works for comparison
  { "tomasr/molokai", lazy = true },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "carbonfox",
      icons = {
        misc = { dots = "..." },
        ft = { octo = "", gh = "", ["markdown.gh"] = "" },
        diagnostics = {
          Error = "E ",
          Warn = "W ",
          Hint = "H ",
          Info = "I ",
        },
        git = {
          added = "+ ",
          modified = "~ ",
          removed = "- ",
        },
        dap = {
          Stopped = { "> ", "DiagnosticWarn", "DapStoppedLine" },
          Breakpoint = "B ",
          BreakpointCondition = "? ",
          BreakpointRejected = { "x ", "DiagnosticError" },
          LogPoint = "L ",
        },
        kinds = kinds,
      },
    },
  },
  {
    "nvim-mini/mini.icons",
    opts = {
      style = "ascii",
      default = {
        directory = { glyph = ">" },
        file = { glyph = "" },
        filetype = { glyph = "" },
      },
    },
  },
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        buffer_close_icon = "x",
        close_icon = "x",
        left_trunc_marker = "<",
        right_trunc_marker = ">",
        modified_icon = "*",
        show_buffer_icons = false,
      },
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "-" },
        topdelete = { text = "-" },
        changedelete = { text = "~" },
        untracked = { text = "?" },
      },
      signs_staged = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "-" },
        topdelete = { text = "-" },
        changedelete = { text = "~" },
      },
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      icons = {
        mappings = false,
        breadcrumb = ">",
        separator = "->",
        group = "+",
        keys = {
          Up = "Up",
          Down = "Down",
          Left = "Left",
          Right = "Right",
          C = "Ctrl-",
          M = "Alt-",
          D = "Cmd-",
          S = "Shift-",
          CR = "Enter",
          Esc = "Esc",
          ScrollWheelDown = "WheelDown",
          ScrollWheelUp = "WheelUp",
          NL = "Enter",
          BS = "Backspace",
          Space = "Space",
          Tab = "Tab",
          F1 = "F1",
          F2 = "F2",
          F3 = "F3",
          F4 = "F4",
          F5 = "F5",
          F6 = "F6",
          F7 = "F7",
          F8 = "F8",
          F9 = "F9",
          F10 = "F10",
          F11 = "F11",
          F12 = "F12",
        },
      },
    },
  },
  {
    "folke/trouble.nvim",
    opts = {
      icons = {
        indent = {
          top = "| ",
          middle = "+-",
          last = "`-",
          fold_open = "v ",
          fold_closed = "> ",
          ws = "  ",
        },
        folder_closed = "> ",
        folder_open = "v ",
        kinds = kinds,
      },
    },
  },
  {
    "folke/todo-comments.nvim",
    opts = {
      keywords = {
        FIX = { icon = "F ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
        TODO = { icon = "T ", color = "info" },
        HACK = { icon = "H ", color = "warning" },
        WARN = { icon = "W ", color = "warning", alt = { "WARNING", "XXX" } },
        PERF = { icon = "P ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
        NOTE = { icon = "N ", color = "hint", alt = { "INFO" } },
        TEST = { icon = "t ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
      },
    },
  },
  {
    "folke/noice.nvim",
    opts = {
      cmdline = { enabled = false },
      popupmenu = { enabled = false },
      presets = {
        bottom_search = false,
        command_palette = false,
      },
    },
  },
  {
    "folke/snacks.nvim",
    opts = {
      scroll = { enabled = false },
      notifier = {
        icons = {
          error = "E ",
          warn = "W ",
          info = "I ",
          debug = "D ",
          trace = "T ",
        },
      },
      picker = {
        prompt = "> ",
        formatters = {
          file = { icon_width = 0 },
          severity = { icons = false, level = true },
        },
        icons = {
          files = { enabled = false, dir = "> ", dir_open = "v ", file = "" },
          keymaps = { nowait = "! " },
          tree = { vertical = "| ", middle = "+-", last = "`-" },
          undo = { saved = "S " },
          ui = {
            live = "L ",
            hidden = "h",
            ignored = "i",
            follow = "f",
            selected = "* ",
            unselected = "  ",
          },
          git = {
            enabled = true,
            commit = "C ",
            staged = "S",
            added = "+",
            deleted = "-",
            ignored = "I",
            modified = "~",
            renamed = ">",
            unmerged = "U",
            untracked = "?",
          },
          diagnostics = { Error = "E ", Warn = "W ", Hint = "H ", Info = "I " },
          lsp = { unavailable = "-", enabled = "+", disabled = "-", attached = "A" },
          kinds = kinds,
        },
      },
      dashboard = {
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          { section = "startup", icon = "" },
        },
        preset = {
          header = [[
NEOVIM
Python | Rust | C | C++ | CUDA
]],
          keys = {
            { icon = "", key = "f", desc = "Find file", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = "", key = "g", desc = "Find text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = "", key = "r", desc = "Recent files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = "", key = "n", desc = "New file", action = ":ene | startinsert" },
            { icon = "", key = "s", desc = "Restore session", section = "session" },
            { icon = "", key = "l", desc = "Plugins", action = ":Lazy" },
            { icon = "", key = "x", desc = "Language extras", action = ":LazyExtras" },
            { icon = "", key = "q", desc = "Quit", action = ":qa" },
          },
        },
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      local icons = LazyVim.config.icons
      opts.options = opts.options or {}
      opts.options.icons_enabled = false
      opts.options.component_separators = { left = "|", right = "|" }
      opts.options.section_separators = { left = "", right = "" }
      opts.sections.lualine_b = { { "branch", icon = "git:" } }
      opts.sections.lualine_c = {
        LazyVim.lualine.root_dir(),
        {
          "diagnostics",
          symbols = {
            error = icons.diagnostics.Error,
            warn = icons.diagnostics.Warn,
            info = icons.diagnostics.Info,
            hint = icons.diagnostics.Hint,
          },
        },
        { LazyVim.lualine.pretty_path() },
      }
      opts.sections.lualine_x = {
        {
          function()
            return "DAP " .. require("dap").status()
          end,
          cond = function()
            return package.loaded.dap and require("dap").status() ~= ""
          end,
        },
        {
          "diff",
          symbols = {
            added = icons.git.added,
            modified = icons.git.modified,
            removed = icons.git.removed,
          },
        },
        "encoding",
        { "fileformat", icons_enabled = false },
        { "filetype", icons_enabled = false },
      }
      opts.sections.lualine_z = {
        function()
          return os.date("%R")
        end,
      }
    end,
  },
  {
    "rcarriga/nvim-dap-ui",
    optional = true,
    opts = {
      icons = { expanded = "v", collapsed = ">", current_frame = ">" },
      controls = {
        icons = {
          pause = "||",
          play = ">",
          step_into = "in",
          step_over = "over",
          step_out = "out",
          step_back = "back",
          run_last = "last",
          terminate = "x",
          disconnect = "off",
        },
      },
    },
  },
}
