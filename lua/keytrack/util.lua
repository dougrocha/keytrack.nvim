local M = {}

---@class Command
---@field lhs string: Left hand side (Should be equivalent to key in array)
---@field desc string: Command description
---@field rhs string|nil: Right hand side of command
---@field callback function|nil: Lua equivalent to rhs
---@field noremap boolean: Noremap value

---Returns all possible commands in normal mode (global and current buffer)
---@param mode string: Mode
---@return Command[]
M.get_all_commands = function(mode)
  ---@type Command[]
  local res = {}

  for _, keymap in ipairs(vim.api.nvim_get_keymap(mode)) do
    ---@diagnostic disable-next-line: undefined-field
    if (keymap.rhs ~= nil and keymap.rhs ~= "") or keymap.callback ~= nil then
      local lhs = M.replace_term_codes(keymap.lhsraw)
      local data = res[lhs] or {}
      data.lhs = lhs
      data.desc = keymap.desc or ""
      data.rhs = keymap.rhs or nil
      data.callback = keymap.callback or nil
      data.noremap = keymap.noremap or false

      res[lhs] = data
    end
  end

  for _, keymap in ipairs(vim.api.nvim_buf_get_keymap(0, mode)) do
    ---@diagnostic disable-next-line: undefined-field
    if (keymap.rhs ~= nil and keymap.rhs ~= "") or keymap.callback ~= nil then
      local lhs = M.replace_term_codes(keymap.lhsraw)
      local data = res[lhs] or {}
      data.lhs = lhs
      data.desc = keymap.desc or ""
      data.rhs = keymap.rhs or nil
      data.callback = keymap.callback or nil
      data.noremap = keymap.noremap or false

      res[lhs] = data
    end
  end

  return res
end

---Replaces terminal codes and key codes with respective values
---@param str string
---@return string
M.replace_term_codes = function(str)
  return vim.api.nvim_replace_termcodes(str, true, false, true)
end

---@param x string
---@return string
M.keytrans = function(x)
  local res = x:gsub("<lt>", "<")
  return res
end

---@param cmd string
M.sanitize_cmd = function(cmd)
  cmd = (cmd .. ""):gsub("%{.*%}$", ""):gsub("%[.*%]$", "")

  if vim.startswith(cmd:lower(), "<cmd>") then
    cmd = cmd:sub(6)
  elseif vim.startswith(cmd, ":") then
    cmd = cmd:sub(2)
  end

  if vim.endswith(cmd:lower(), "<cr>") then
    cmd = cmd:sub(1, #cmd - 4)
  elseif vim.endswith(cmd, "\r") then
    cmd = cmd:sub(1, #cmd - 2)
  end

  return vim.trim(cmd)
end

---@param keys string
---@param noremap boolean
M.execute_cmd = function(keys, noremap)
  local count = vim.v.count1

  local mode = "t"
  if noremap then
    mode = mode .. "m"
  end

  if vim.startswith(keys, ":") or vim.startswith(keys, "<cmd>") then
    vim.api.nvim_cmd({
      cmd = M.sanitize_cmd(keys),
      count = count,
    }, {
      output = false,
    })
  end

  local is_expr, evaluated_cmd = pcall(vim.api.nvim_eval, keys)

  if is_expr then
    keys = evaluated_cmd
    mode = "nx"
  end

  vim.api.nvim_feedkeys(count .. M.replace_term_codes(keys), mode, true)
end

return M
