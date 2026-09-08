return {
  {
    "jay-babu/mason-nvim-dap.nvim",
    opts = {
      automatic_installation = false,
      ensure_installed = { "codelldb" },
    },
  },
  {
    "mfussenegger/nvim-dap-python",
    config = function()
      require("dap-python").setup(vim.fn.exepath("debugpy-adapter"))
    end,
  },
  {
    "nvim-neotest/neotest",
    dependencies = {
      "orjangj/neotest-ctest",
    },
    opts = {
      icons = {
        running_animated = { "/", "|", "\\", "-" },
        passed = "+",
        running = ">",
        failed = "x",
        skipped = "-",
        unknown = "?",
        non_collapsible = "-",
        collapsed = ">",
        expanded = "v",
        child_prefix = "+",
        final_child_prefix = "`",
        child_indent = "|",
        final_child_indent = " ",
        watching = "w",
        test = "t",
        notify = "!",
        dir = "d",
        file = "f",
        namespace = "n",
      },
      adapters = {
        ["neotest-ctest"] = {
          dap_adapter = "codelldb",
          is_test_file = function(file)
            return file:match("[_%.]test%.[cC][cCpPxX+]*$") ~= nil
              or file:match("[_%.]test%.cu$") ~= nil
              or file:match("test[_%.].*%.[cC][cCpPxX+]*$") ~= nil
              or file:match("test[_%.].*%.cu$") ~= nil
          end,
        },
      },
    },
  },
  {
    "mfussenegger/nvim-dap",
    opts = function()
      local dap = require("dap")
      dap.adapters.cuda_gdb = {
        type = "executable",
        command = "cuda-gdb",
        args = {
          "--interpreter=dap",
          "--eval-command",
          "set print pretty on",
        },
      }
      dap.configurations.cuda = {
        {
          name = "CodeLLDB: Launch CUDA host code",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
        {
          name = "CUDA-GDB: Launch executable",
          type = "cuda_gdb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to CUDA executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopAtBeginningOfMainSubprogram = false,
        },
        {
          name = "CUDA-GDB: Attach to process",
          type = "cuda_gdb",
          request = "attach",
          program = function()
            return vim.fn.input("Path to CUDA executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          pid = require("dap.utils").pick_process,
          cwd = "${workspaceFolder}",
        },
      }
    end,
  },
}
