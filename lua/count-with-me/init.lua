local Tracker = require("count-with-me.tracker")
local Utils = require("count-with-me.util")

---@class CountWithMe
local M = {}
local H = {}

---@class Track
---@field key string: lhs of command
---@field desc string: description of command (may not be used)

---Config for CountWithMe
---@class CountWithMeConfig
---@field active? Track[]
---@field suffix? string: Add suffix to command description when tracking
M.config = {
  -- Array of keybinds to keep track of
  active = {
    { key = "<leader>sf", desc = "Search Files with telescope" },
    { key = "<leader>a", desc = "Add harpoon file" },
    { key = "<leader>fw", desc = "Search for word under cursor" },
    { key = "<leader>/", desc = "Grep workspace" },
    { key = "<leader>bn", desc = "Next buffer" },
  },
  suffix = "Tracking",
}

---Count With Me Setup
---@param config CountWithMeConfig CountWithMe config table. See |CountWithMe.config|.
M.setup = function(config)
  vim.validate({
    config = { config.active, "table", true },
    suffix = { config.suffix, "string", true },
  })
  M.config = vim.tbl_deep_extend("force", vim.deepcopy(M.config), config or {})

  H.cmds_cache = Utils.get_all_commands("m")
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

  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = au_group,
    pattern = "*",
    callback = vim.schedule_wrap(function()
      -- handle saving tracking buffer to file
    end),
    desc = "Check all triggers",
  })
end

---All cmds loaded at start
H.cmds_cache = {}
---Stores the original commands to revert back to normal
---@type Command[]
H.pre_track_cmds = {}

---Remove trackers and re-register them
M.check_trackers = function()
  M.remove_all_trackers()
  M.register_all_trackeres()
end

---Register multiple triggers
M.register_all_trackeres = function()
  for _, tracker in ipairs(M.config.active) do
    M.register_trackers(tracker)
  end
end

---Remove all trackers
M.remove_all_trackers = function()
  for _, trigger in ipairs(M.config.active) do
    M.remove_tracker(trigger)
  end

  H.cmds_cache = Utils.get_all_commands("n")
end

---@param tracker Track
M.remove_tracker = function(tracker)
  tracker.key = Utils.replace_term_codes(tracker.key)
  local key = Utils.keytrans(tracker.key)

  if H.pre_track_cmds[key] then
    local cmd = H.pre_track_cmds[key]
    pcall(vim.keymap.del, "n", key, {})

    local rhs = cmd.rhs or cmd.callback or ""

    local desc = cmd.desc or ""
    local opts = { desc = desc, noremap = cmd.noremap }
    pcall(vim.keymap.set, "n", key, rhs, opts)

    H.pre_track_cmds[key] = nil
  end
end

---Register a single tracker
---@param tracker Track
M.register_trackers = function(tracker)
  local cmds = H.cmds_cache
  tracker.key = Utils.replace_term_codes(tracker.key)
  local key = Utils.keytrans(tracker.key)

  local cmd = cmds[key]

  if cmd == nil then
    return
  end

  -- save command
  H.pre_track_cmds[key] = cmd

  local tracked_rhs = function()
    -- handle tracking
    Tracker.increment_entry(cmd)

    if cmd.rhs then
      local parsed_rhs = Utils.clean_up_rhs(cmd.rhs)
      local cmd, args = Utils.parse_cmd_and_args(parsed_rhs)
      vim.cmd({ cmd = cmd, args = args })

      return
    end

    if cmd.callback then
      cmd.callback()
      return
    end
  end

  local desc = cmd.desc .. " (tracked)"
  local opts = { nowait = true, desc = desc, noremap = cmd.noremap }
  vim.keymap.set("n", key, tracked_rhs, opts)
end

return M
