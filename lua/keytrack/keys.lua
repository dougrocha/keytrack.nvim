local Path = require("plenary.path")

local data_path = vim.fn.stdpath("data") .. "\\keytrack.json"

local M = {}

local function write_file(file_path, encoded_json)
  Path:new(file_path):write(encoded_json, "w")
end

local function read_file(file_path)
  return vim.fn.json_decode(Path:new(file_path):read())
end

M.load_file = function()
  local ok, data = pcall(read_file, data_path)

  if not ok then
    M.active_cmds = {}
    pcall(write_file, data_path, vim.fn.json_encode(M.active_cmds))
    return
  end

  M.active_cmds = data
end

M.save_to_file = function()
  local data = M.active_cmds

  -- switch each <Leader> value with the `<Leader>` string to make it easier to ready in file
  for _, val in pairs(data) do
    val.lhs = val.lhs:gsub(" ", "<leader>")
  end

  pcall(write_file, data_path, vim.fn.json_encode(data))
end

---Command class with count param
---@class CommandWithCount
---@field count number: Amount of times command has been used
---@field lhs string: Left hand side (Should be equivalent to key in array)
---@field desc string: Command description
---@field rhs string|nil: Right hand side of command
---@field callback function|nil: Lua equivalent to rhs

---Keep track of active commands with count, so not to write to file too often
---@type table<string, CommandWithCount>
M.active_cmds = {}

---Transform cmd to key string
---@param cmd Command|string
local cmd_to_key = function(cmd)
  return type(cmd) == "string" and cmd or cmd.lhs
end

---Track cmd
---@param cmd Command|string: Command or lhs
M.add_entry = function(cmd)
  local key = cmd_to_key(cmd)

  if M.active_cmds[key] then
    return
  end

  local entry = {
    count = 0,
    lhs = key:gsub(" ", "<leader>"),
    desc = cmd.desc or "",
    rhs = cmd.rhs,
  }

  -- track things here
  M.active_cmds[key] = entry
end

---Remove command
---@param cmd Command|string: Command or lhs
M.delete_command = function(cmd)
  local key = cmd_to_key(cmd)

  if M.active_cmds[key] then
    return
  end

  M.active_cmds[key] = nil
end

---Increment command
---@param cmd Command|string: Command struct or lhs value
---@param count number|nil - Defaults to 1
M.increment_cmd = function(cmd, count)
  count = count or 1

  local key = cmd_to_key(cmd)
  local prev_cmd = M.active_cmds[key]

  local prev_count = prev_cmd.count or 0
  M.active_cmds[key] = {
    count = prev_count + count,
    lhs = key:gsub(" ", "<leader>"),
    desc = prev_cmd.desc,
    rhs = prev_cmd.rhs,
  }
end

---Will reset command to zero
---@param cmd Command
M.reset_entry = function(cmd)
  local key = cmd_to_key(cmd)
  local prev_cmd = M.active_cmds[key]

  M.active_cmds[key] = {
    count = 0,
    lhs = key:gsub(" ", "<leader>"),
    desc = prev_cmd.desc,
    rhs = prev_cmd.rhs,
    callback = prev_cmd.callback,
  }
end

return M
