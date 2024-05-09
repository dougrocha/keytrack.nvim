local Tracking = require("count-with-me.tracking")
local Utils = require("count-with-me.utils")

---@class CountWithMe
local M = {}
local H = {}

---@class Track
---@field key string: lhs of command
---@field desc string: description of command (may not be used)

---Config for CountWithMe
---@class CountWithMeConfig
---@field track? Track[]
---@field suffix? string: Add suffix to command description when tracking
M.config = {
  -- Array of keybinds to keep track of
  track = {
    { key = "<leader>sf", desc = "Search Files with telescope" },
    { key = "<leader>a", desc = "Add harpoon file" },
  },
  suffix = "Tracking",
}

---Count With Me Setup
---@param config CountWithMeConfig|nil CountWithMe config table. See |CountWithMe.config|.
M.setup = function(config)
  vim.validate({
    config = { config.track, "table", true },
    suffix = { config.suffix, "string", true },
  })
  M.config = vim.tbl_deep_extend("force", vim.deepcopy(M.config), config or {})

  M.check_trackers()
  H.setup_autocommands()
end

H.setup_autocommands = function()
  local au_group = vim.api.nvim_create_augroup("CountWithMe", {})

  local cb = vim.schedule_wrap(function()
    M.check_trackers()
  end)

  vim.api.nvim_create_autocmd({ "BufAdd", "LspAttach" }, {
    group = au_group,
    pattern = "*",
    callback = cb,
    desc = "Check all triggers",
  })
end

---Remove trackers and re-register them
M.check_trackers = function()
  M.remove_all_trackers()
  M.register_all_trackeres()
end

---Remove all trackers
M.remove_all_trackers = function()
  for _, trigger in ipairs(M.config.track) do
    M.remove_tracker(trigger)
  end
end

---@param tracker Track
M.remove_tracker = function(tracker)
  tracker.key = Utils.replace_term_codes(tracker.key)
  local key = Utils.keytrans(tracker.key)

  if H.commands_without_tracker[key] then
    local cmd = H.commands_without_tracker[key]
    pcall(vim.keymap.del, "n", key, {})

    local rhs = cmd.rhs or cmd.callback or ""

    local desc = cmd.desc or ""
    local opts = { desc = desc }
    pcall(vim.keymap.set, "n", key, rhs, opts)

    H.commands_without_tracker[key] = nil
  end
end

---Stores the regular commands so I can remove the track and revert it back to normal
---@type Command[]
H.commands_without_tracker = {}

---Register a single tracker
---@param tracker Track
M.register_trackers = function(tracker)
  local cmds = Utils.get_all_commands("m")
  tracker.key = Utils.replace_term_codes(tracker.key)
  local key = Utils.keytrans(tracker.key)

  local cmd = cmds[key]

  if cmd == nil then
    return
  end

  -- save command
  H.commands_without_tracker[key] = cmd

  local tracker_rhs = function()
    -- handle tracking
    Tracking.track(cmd)

    if cmd.rhs then
      local rhs = cmd.rhs:gsub("<cmd>", "")
      rhs = rhs:sub("<cr>", "")
      vim.api.nvim_exec2(rhs, {})
      return
    end

    if cmd.callback then
      cmd.callback()
      return
    end
  end

  local desc = cmd.desc .. " (tracked)"
  local opts = { nowait = true, desc = desc }
  vim.keymap.set("n", key, tracker_rhs, opts)
end

---Register multiple triggers
M.register_all_trackeres = function()
  for _, tracker in ipairs(M.config.track) do
    M.register_trackers(tracker)
  end
end

return M
