return {
  { "stevearc/overseer.nvim" },
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      local function disable_overseer_icons(section)
        for _, component in ipairs(section or {}) do
          if type(component) == "table" and component[1] == "overseer" then
            component.icons_enabled = false
          end
        end
      end
      for _, section in pairs(opts.sections or {}) do
        disable_overseer_icons(section)
      end
      for _, section in pairs(opts.inactive_sections or {}) do
        disable_overseer_icons(section)
      end
    end,
  },
}
