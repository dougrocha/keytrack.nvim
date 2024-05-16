local config = {
  auto = false,
  keymaps = {},
  disabled = {},
  suffix = "",
}

---@class Config
---@field auto boolean: Automatically setup keybinds
---@field keymaps {key: string, desc: string}[]
---@field disabled {key: string, desc: string}[]
---@field suffix string
---@field log_level string
local M = setmetatable({}, {
  __index = function(_, key)
    return config[key]
  end,
  __newindex = function(_, key, value)
    config[key] = value
  end,
})

---@param user_config? Config
M.setup = function(user_config)
  M.config = vim.tbl_deep_extend("force", config, user_config or {})
end

return M
