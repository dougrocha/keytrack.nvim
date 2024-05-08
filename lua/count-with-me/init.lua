local Utils = require("count-with-me.utils")

---@class CountWithMe
local M = {}
local H = {}

---@class CountWithMeConfig
---@field triggers table
---@field clues table
M.config = {
  --- trigger to activate plugin
  triggers = {
    { mode = "n", key = "<Leader>" },
  },
  -- Array of keybinds to keep track of
  clues = {
    { key = "<Leader>sf", desc = "Testing thing" },
    { key = "<Leader>fw", desc = "Testing another thing" },
  },
}

H.state = {
  trigger = nil,
  clues = {},
  raw_query = {},
}

---Predetermined keys
H.keys = {
  BS = vim.api.nvim_replace_termcodes("<BS>", true, true, true),
  CR = vim.api.nvim_replace_termcodes("<CR>", true, true, true),
  EXIT = vim.api.nvim_replace_termcodes([[<C-\><C-n>]], true, true, true),
}

H.reset_state = function()
  H.state.trigger = nil
  H.state.clues = {}
  H.state.raw_query = {}
end

H.set_state = function(trigger, key)
  H.state.trigger = trigger
  H.state.raw_query = key
  H.state.clues = H.get_next_clues(key)
end

H.pop_state = function()
  -- remove last item in raw_query
  H.state.raw_query[#H.state.raw_query] = nil
  H.state.clues = H.get_next_clues(H.state.raw_query)
end

H.push_state = function(key)
  table.insert(H.state.raw_query, key)
  H.state.clues = H.get_next_clues(H.state.raw_query)
end

H.is_state_runnable = function()
  local query = table.concat(H.state.raw_query, "")

  if H.state.clues[query] then
    return true
  end

  return false
end

H.get_next_clues = function(key)
  local filtered_res = Utils.filter_by_query(Utils.cmds_cache, key)
  return filtered_res
end

H.advance_state = function()
  local input_key = H.getcharstr()

  if input_key == nil then
    return H.reset_state()
  end

  if input_key == H.keys.BS then
    H.pop_state()
  else
    H.push_state(input_key)
  end

  -- handle query being at a keymap
  if H.is_state_runnable() then
    return H.execute_state()
  end

  if #H.state.raw_query == 0 then
    return H.reset_state()
  end

  if vim.tbl_count(H.state.clues) >= 1 then
    return H.advance_state()
  end

  H.execute_state()
end

H.temp_state = {}

---Execute Command
H.execute_state = function()
  local keys = table.concat(H.state.raw_query, "")
  local trigger = H.state.trigger

  -- remove trigger
  M.remove_trigger(trigger)

  --run keymap
  --m = remap keys
  --i = insert instead of append
  --t = handle keys as if user typed them
  --escape_ks is true since we already configured keys with replace_term_codes
  vim.api.nvim_feedkeys(keys, "mit", true)

  ---handle counting of cmds
  if H.temp_state[keys] == nil then
    H.temp_state[keys] = { count = 1 }
  else
    H.temp_state[keys].count = H.temp_state[keys].count + 1
  end

  P(H.temp_state)

  --schedule register trigger after keymap has ran
  vim.schedule(function()
    M.register_trigger(trigger)
  end)
end

H.getcharstr = function()
  local ok, char = pcall(vim.fn.getcharstr)
  if not ok or char == "\27" or char == "" then
    return
  end
  return char
end

---Count With Me Setup
---@param config CountWithMeConfig|nil CountWithMe config table. See |CountWithMe.config|.
M.setup = function(config)
  M.config = vim.tbl_deep_extend("force", vim.deepcopy(M.config), config or {})

  -- use a cmd cache to store all cmds and clues
  Utils.cmds_cache = Utils.get_all_commands("n", M.config.clues)

  M.register_triggers(M.config.triggers)
end

---@param trigger table
M.remove_trigger = function(trigger)
  trigger.key = Utils.replace_term_codes(trigger.key)
  local key = Utils.keytrans(trigger.key)

  vim.keymap.del("n", key, {})
end

---Register a single trigger
---@param trigger table
M.register_trigger = function(trigger)
  trigger.key = Utils.replace_term_codes(trigger.key)
  local key = Utils.keytrans(trigger.key)

  local trigger_rhs = function()
    H.set_state(trigger, { trigger.key })

    H.advance_state()
  end

  local desc = "Query keys for " .. key
  local opts = { nowait = true, desc = desc }
  vim.keymap.set("n", key, trigger_rhs, opts)
end

---Register multiple triggers
---@param triggers table
M.register_triggers = function(triggers)
  for _, trigger in ipairs(triggers) do
    M.register_trigger(trigger)
  end
end

return M
