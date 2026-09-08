return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "c",
        "cmake",
        "cpp",
        "cuda",
        "ninja",
        "python",
        "ron",
        "rust",
        "starlark",
        "toml",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        basedpyright = {
          mason = false,
          cmd = { "basedpyright-langserver", "--stdio" },
          settings = {
            basedpyright = {
              analysis = {
                autoImportCompletions = true,
                diagnosticMode = "openFilesOnly",
              },
              disableOrganizeImports = true,
            },
          },
        },
        ruff = {
          mason = false,
          cmd = { "ruff", "server" },
        },
        clangd = {
          mason = false,
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
            "--query-driver=/usr/bin/clang*,/usr/bin/gcc*,/usr/bin/g++*",
          },
          filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
        },
      },
    },
  },
  {
    "p00f/clangd_extensions.nvim",
    ft = { "c", "cpp", "objc", "objcpp", "cuda" },
    opts = {
      ast = {
        role_icons = {
          type = "T",
          declaration = "D",
          expression = "E",
          specifier = "S",
          statement = ">",
          ["template argument"] = "A",
        },
        kind_icons = {
          Compound = "C",
          Recovery = "R",
          TranslationUnit = "U",
          PackExpansion = "P",
          TemplateTypeParm = "T",
          TemplateTemplateParm = "T",
          TemplateParamObject = "O",
        },
      },
    },
  },
  {
    "mrcjkb/rustaceanvim",
    version = "^9",
    opts = function(_, opts)
      opts.tools = vim.tbl_deep_extend("force", opts.tools or {}, {
        enable_clippy = true,
        enable_nextest = false,
      })
      local settings = opts.server.default_settings["rust-analyzer"]
      settings.cargo.allFeatures = nil
      settings.cargo.loadOutDirsFromCheck = nil
      settings.cargo.features = "all"
      settings.cargo.buildScripts = { enable = true }
      settings.procMacro = { enable = true }
      settings.checkOnSave = false
      return opts
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = {
      default_format_opts = {
        timeout_ms = 10000,
        async = false,
        quiet = false,
        lsp_format = "fallback",
      },
      formatters_by_ft = {
        python = { "ruff_organize_imports", "ruff_format" },
        rust = { "rustfmt", lsp_format = "fallback" },
        c = { "clang-format" },
        cpp = { "clang-format" },
        cuda = { "clang-format" },
        cmake = { "cmake_format" },
        bzl = { "buildifier" },
      },
      formatters = {
        ["clang-format"] = { command = "clang-format" },
        buildifier = { command = "buildifier" },
        ruff_format = { command = "ruff" },
        ruff_organize_imports = { command = "ruff" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters = {
        cmakelint = {
          cmd = "cmake-lint",
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.PATH = "append"
      local seen = {}
      opts.ensure_installed = vim.tbl_filter(function(tool)
        if tool == "cmakelang" or tool == "cmakelint" or seen[tool] then
          return false
        end
        seen[tool] = true
        return true
      end, opts.ensure_installed or {})
      opts.ui = vim.tbl_deep_extend("force", opts.ui or {}, {
        icons = {
          package_installed = "+",
          package_pending = "~",
          package_uninstalled = "-",
        },
      })
      return opts
    end,
  },
  {
    "Civitasv/cmake-tools.nvim",
    opts = {
      cmake_generate_options = { "-DCMAKE_EXPORT_COMPILE_COMMANDS=1" },
      cmake_compile_commands_options = {
        action = "soft_link",
        target = vim.uv.cwd,
      },
      cmake_dap_configuration = {
        name = "CMake target",
        type = "codelldb",
        request = "launch",
        stopOnEntry = false,
        runInTerminal = true,
      },
    },
  },
}
