local overseer = require("overseer")

local function find_root(dir)
  local marker = vim.fs.find({ "MODULE.bazel", "WORKSPACE.bazel", "WORKSPACE" }, {
    upward = true,
    type = "file",
    path = dir,
  })[1]
  return marker and vim.fs.dirname(marker) or nil
end

return {
  cache_key = function(opts)
    return find_root(opts.dir)
  end,
  generator = function(opts)
    local root = find_root(opts.dir)
    if not root then
      return "No Bazel workspace found"
    end
    if vim.fn.executable("bazel") == 0 then
      return 'Command "bazel" not found'
    end

    local function task(verb, tag)
      return {
        name = "bazel " .. verb,
        desc = "Run bazel " .. verb .. " for a target",
        tags = { tag },
        params = {
          target = {
            type = "string",
            default = "//...",
            desc = "Bazel target pattern",
          },
          args = {
            type = "string",
            default = "",
            optional = true,
            desc = "Additional Bazel arguments",
          },
        },
        builder = function(params)
          local args = { verb, params.target }
          if params.args and params.args ~= "" then
            vim.list_extend(args, vim.split(params.args, "%s+", { trimempty = true }))
          end
          return {
            cmd = { "bazel" },
            args = args,
            cwd = root,
            components = {
              { "on_output_quickfix", open = false },
              "default",
            },
          }
        end,
      }
    end

    return {
      task("build", overseer.TAG.BUILD),
      task("test", overseer.TAG.TEST),
      task("run", overseer.TAG.RUN),
    }
  end,
}
