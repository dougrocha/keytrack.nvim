---@class CommandWithCount
---@field count number: Amount of times command has been used
---@field lhs string: Left hand side (Should be equivalent to key in array)
---@field desc string: Command description
---@field rhs string|nil: Right hand side of command
---@field callback function|nil: Lua equivalent to rhs

local Path = require("plenary.path")

local data_path = vim.fn.stdpath("data")
local json_path = data_path .. "\\count-with-me.json"

local M = {}

M.data_path = data_path

---@type CommandWithCount[]
M.cached_tracked = {}

---Transform cmd to key string
---@param cmd Command|string
local cmd_to_key = function(cmd)
  return type(cmd) == "string" and cmd or cmd.lhs
end

---Track cmd
---@param cmd Command
M.add_entry = function(cmd)
  local key = cmd_to_key(cmd)

  if M.cached_tracked[key] then
    return
  end

  local entry = {
    count = 0,
    lhs = key,
    desc = cmd.desc or "",
    rhs = cmd.rhs,
  }

  -- track things here
  M.cached_tracked[key] = entry
end

---Remove entry
---@param cmd Command|string: Command struct or lhs value
M.remove_entry = function(cmd)
  local key = cmd_to_key(cmd)

  if M.cached_tracked[key] then
    return
  end

  M.cached_tracked[key] = nil
end

---Increment entry (usually by 1)
---@param cmd Command
---@param count number|nil
M.increment_entry = function(cmd, count)
  count = count or 1

  local key = cmd_to_key(cmd)
  local prev_cmd = M.cached_tracked[key]

  local prev_count = prev_cmd.count or 0
  M.cached_tracked[key] = {
    count = prev_count + count,
    lhs = key,
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
    lhs = key,
    desc = prev_cmd.desc,
    rhs = prev_cmd.rhs,
    callback = prev_cmd.callback,
  }
end

local function write_file(file_path, encoded_json)
  Path:new(file_path):write(encoded_json, "w")
end

local function read_file(file_path)
  return vim.fn.json_decode(Path:new(file_path):read())
end

M.load_file = function()
  local ok, data = pcall(read_file, json_path)

  if not ok then
    M.cached_tracked = {}
    pcall(write_file, file_path, vim.fn.json_encode(M.cached_tracked))
    return
  end

  M.cached_tracked = data
end

M.save_to_file = function()
  local data = M.cached_tracked

  -- switch each <Leader> value with the `<Leader>` string to make it easier to ready in file
  for _, val in pairs(data) do
    val.lhs = val.lhs:gsub(" ", "<leader>")
  end

  pcall(write_file, json_path, vim.fn.json_encode(data))
end

return M
