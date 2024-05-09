local Utils = {}

---@class Command
---@field lhs string: Left hand side (Should be equivalent to key in array)
---@field desc string: Command description
---@field rhs? string: Right hand side of command
---@field callback? function: Lua equivalent to rhs

---Returns all possible commands in normal mode (global and current buffer)
---@param mode string
---@return Command[]
Utils.get_all_commands = function(mode)
  ---@type Command[]
  local res = {}

  for _, keymap in ipairs(vim.api.nvim_get_keymap(mode)) do
    local lhs = Utils.replace_term_codes(keymap.lhsraw)
    local data = res[lhs] or {}
    data.desc = keymap.desc or ""
    data.rhs = keymap.rhs or nil
    data.callback = keymap.callback or nil

    res[lhs] = data
  end

  for _, keymap in ipairs(vim.api.nvim_buf_get_keymap(0, mode)) do
    local lhs = Utils.replace_term_codes(keymap.lhsraw)
    local data = res[lhs] or {}
    data.desc = keymap.desc or ""
    data.rhs = keymap.rhs or nil
    data.callback = keymap.callback or nil

    res[lhs] = data
  end

  return res
end

---Replaces terminal codes and key codes with respective values
---@param str string
---@return string|nil
Utils.replace_term_codes = function(str)
  if str == nil then
    return nil
  end

  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

---@param x string
---@return string
Utils.keytrans = function(x)
  local res = x:gsub("<lt>", "<")
  return res
end

return Utils
