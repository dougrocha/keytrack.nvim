local Path = require("plenary.path")

local data_path = vim.fn.stdpath("data")

local M = {}

M.data_path = data_path

M.cached_tracked = {}

---Track cmd
---@param cmd Command
M.add_entry = function(cmd)
  local entry = {
    count = 0,
    lhs = cmd.lhs,
    desc = cmd.desc,
    rhs = cmd.rhs,
  }

  -- track things here
  M.cached_tracked[cmd.lhs] = entry
end

---Transform cmd to key string
---@param cmd Command|string
local cmd_to_key = function(cmd)
  return type(cmd) == "string" and cmd or cmd.lhs
end

---Remove entry
---@param cmd Command|string: Command struct or lhs value
M.remove_entry = function(cmd)
  local key = cmd_to_key(cmd)

  M.cached_tracked[key] = nil
end

---Increment entry (usually by 1)
---@param cmd Command
---@param count number|nil
M.increment_entry = function(cmd, count)
  count = count or 1

  local key = cmd_to_key(cmd)
  local prev_cmd = M.cached_tracked[key]

  M.cached_tracked[key] = {
    count = prev_cmd.count + count,
    lhs = prev_cmd.lhs,
    desc = prev_cmd.desc,
    rhs = prev_cmd.rhs,
  }
end

---Will reset entry to zero
---@param cmd Command
M.reset_entry = function(cmd)
  local key = cmd_to_key(cmd)
  local prev_cmd = M.cached_tracked[key]

  M.cached_tracked[key] = {
    count = 0,
    lhs = prev_cmd.lhs,
    desc = prev_cmd.desc,
    rhs = prev_cmd.rhs,
  }
end

M.save_to_file = function()
  -- handle saving to file here
  -- this could be ran manually but will most likely be ran with an autocommand set to BufWritePost
end

return M
