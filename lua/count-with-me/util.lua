local M = {}

---@class Command
---@field lhs string: Left hand side (Should be equivalent to key in array)
---@field desc string: Command description
---@field rhs string|nil: Right hand side of command
---@field callback function|nil: Lua equivalent to rhs
---@field noremap boolean: Noremap value

---Returns all possible commands in normal mode (global and current buffer)
---@param mode string
---@return Command[]
M.get_all_commands = function(mode)
  ---@type Command[]
  local res = {}

  for _, keymap in ipairs(vim.api.nvim_get_keymap(mode)) do
    local lhs = M.replace_term_codes(keymap.lhsraw)
    local data = res[lhs] or {}
    data.lhs = lhs
    data.desc = keymap.desc or ""
    data.rhs = keymap.rhs or nil
    data.callback = keymap.callback or nil
    data.noremap = keymap.noremap or false

    res[lhs] = data
  end

  for _, keymap in ipairs(vim.api.nvim_buf_get_keymap(0, mode)) do
    local lhs = M.replace_term_codes(keymap.lhsraw)
    local data = res[lhs] or {}
    data.lhs = lhs
    data.desc = keymap.desc or ""
    data.rhs = keymap.rhs or nil
    data.callback = keymap.callback or nil
    data.noremap = keymap.noremap or false

    res[lhs] = data
  end

  return res
end

---Replaces terminal codes and key codes with respective values
---@param str string
---@return string|nil
M.replace_term_codes = function(str)
  if str == nil then
    return nil
  end

  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

---@param x string
---@return string
M.keytrans = function(x)
  local res = x:gsub("<lt>", "<")
  return res
end

---Clean up rhs by removing `<Cmd>` and `<CR>`
---@param rhs_str string
---@return string
M.clean_up_rhs = function(rhs_str)
  local rhs = string.gsub(rhs_str, "<Cmd>", "")
  rhs = string.gsub(rhs, "<CR>", "")
  return rhs
end

---Parse cmd and args for rhs
---@param str string
---@return string
---@return string[]
M.parse_cmd_and_args = function(str)
  -- Split the string into words
  local words = {}
  for word in str:gmatch("%S+") do
    table.insert(words, word)
  end

  -- Extract the first word
  ---@type string
  local cmd = words[1]

  -- Extract the arguments (if any)
  local args = {}
  for i = 2, #words do
    table.insert(args, words[i])
  end

  return cmd, args
end

-- local test = function()
--   local mode = "n"
--
--   local data = {}
--
--   for _, keymap in ipairs(vim.api.nvim_get_keymap(mode)) do
--     if (keymap.rhs ~= nil and keymap.rhs ~= "") or keymap.callback ~= nil then
--       P(keymap)
--     end
--   end
--
--   for _, keymap in ipairs(vim.api.nvim_buf_get_keymap(0, mode)) do
--     if (keymap.rhs ~= nil and keymap.rhs ~= "") or keymap.callback ~= nil then
--       P(keymap)
--     end
--   end
--
--   P(data)
-- end
--
-- test()

return M
