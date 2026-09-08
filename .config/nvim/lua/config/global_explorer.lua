local M = {}

local enabled = false
local syncing = false
local active_root

local function command(action)
  require("neo-tree.command").execute({
    action = action,
    source = "filesystem",
    position = "left",
    dir = active_root or LazyVim.root(),
  })
end

function M.show()
  enabled = true
  active_root = LazyVim.root()
  command("show")
end

function M.close_all()
  enabled = false
  syncing = true
  require("neo-tree.sources.manager")._for_each_state("filesystem", function(state)
    require("neo-tree.ui.renderer").close(state)
  end)
  syncing = false
end

function M.toggle()
  if enabled then
    M.close_all()
  else
    M.show()
  end
end

function M.is_enabled()
  return enabled
end

local group = vim.api.nvim_create_augroup("global_neo_tree", { clear = true })
vim.api.nvim_create_autocmd("TabEnter", {
  group = group,
  callback = function()
    if enabled and not syncing then
      vim.schedule(function()
        if enabled then
          command("show")
        end
      end)
    end
  end,
})

return M
