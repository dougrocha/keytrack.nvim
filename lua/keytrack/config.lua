---@class Config
local defaults = {
  ---@type {key: string, desc: string}[]
  active = {},
  ---@type {key: string, desc: string}[]
  disabled = {},
  suffix = "",
}

local M = {}

---@type Config
M.config = {}

---@param user_config? Config
M.setup = function(user_config)
  M.config = vim.tbl_deep_extend("force", {}, vim.deepcopy(defaults), user_config or {})
end

return M
