---@class Config
---@field auto boolean: Automatically setup keybinds
---@field keymaps {key: string, desc: string}[]
---@field disabled {key: string, desc: string}[]
---@field suffix string
---@field log_level string
local M = {}

M.config = {
  auto = false,
  keymaps = {},
  disabled = {},
  suffix = "",
}

---@param user_config? Config
M.setup = function(user_config)
  M.config = vim.tbl_deep_extend("force", M.config, user_config or {})
end

return M
