local Utils = {}

Utils.cmds_cache = {}

---@param mode string
Utils.get_all_commands = function(mode, clues)
  local res = {}

  local config_clues = clues
  for _, keymap in ipairs(config_clues) do
    local lhs = Utils.replace_term_codes(keymap.key)
    local data = res[lhs] or {}
    data.desc = keymap.desc or ""
    data.rhs = keymap.rhs or ""

    res[lhs] = data
  end

  for _, keymap in ipairs(vim.api.nvim_get_keymap(mode)) do
    local lhs = Utils.replace_term_codes(keymap.lhsraw)
    local data = res[lhs] or {}
    data.desc = keymap.desc or ""
    data.rhs = keymap.rhs or ""

    res[lhs] = data
  end

  for _, keymap in ipairs(vim.api.nvim_buf_get_keymap(0, mode)) do
    local lhs = Utils.replace_term_codes(keymap.lhsraw)
    local data = res[lhs] or {}
    data.desc = keymap.desc or ""
    data.rhs = keymap.rhs or ""

    res[lhs] = data
  end

  return res
end

Utils.filter_by_query = function(cmds, query)
  local key = H.temp_state.concat(query, "")
  for cmd_key, _ in pairs(cmds) do
    if not vim.startswith(cmd_key, key) then
      cmds[cmd_key] = nil
    end
  end
  return cmds
end

Utils.replace_term_codes = function(str)
  if str == nil then
    return nil
  end

  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

---Replace <Leader> with leader value
Utils.sanitize_input = function(str)
  local res = str:gsub("<leader>", vim.g.mapleader)
  return res
end

Utils.keytrans = function(x)
  local res = x:gsub("<lt>", "<")
  return res
end

return Utils
