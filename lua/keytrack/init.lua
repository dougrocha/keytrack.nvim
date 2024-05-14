local Config = require("keytrack.config")
local Tracker = require("keytrack.tracker")
local UI = require("keytrack.ui")
local Utils = require("keytrack.util")

---@class KeyTrack
local M = {}
local H = {}

---KeyTrack Setup
---@param user_config Config
M.setup = function(user_config)
  Config.setup(user_config)

  Tracker.load_file()

  H.cmds_cache = Utils.get_all_commands("m")
  H.setup_autocommands()
end

---Open window
M.open_window = function()
  UI.open()
end

---Close window
M.close_window = function()
  UI.close()
end

H.setup_autocommands = function()
  local au_group = vim.api.nvim_create_augroup("KeyTrack", {})

  local cb = vim.schedule_wrap(function()
    M.check_trackers()
  end)

  vim.api.nvim_create_autocmd({ "BufAdd", "LspAttach" }, {
    group = au_group,
    pattern = "*",
    callback = cb,
    desc = "Check all active trackers",
  })

  vim.api.nvim_create_autocmd({ "BufLeave", "VimLeave" }, {
    group = au_group,
    pattern = "*",
    callback = vim.schedule_wrap(function()
      Tracker.save_to_file()
    end),
    desc = "Save trackers to file",
  })
end

---All cmds loaded at start
---@type Command[]
H.cmds_cache = {}
---Stores the original commands to revert back to normal
---@type Command[]
H.pre_track_cmds = {}

---Remove trackers and re-register them
M.check_trackers = function()
  M.remove_all_trackers()
  M.register_all_trackers()
end

---Register multiple triggers
M.register_all_trackers = function()
  for _, tracker in ipairs(Config.active) do
    M.register_trackers(tracker)
  end
end

---Remove all trackers
M.remove_all_trackers = function()
  for _, trigger in ipairs(Config.active) do
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
  Tracker.add_entry(cmd)

  local tracked_rhs = function()
    -- handle tracking
    Tracker.increment_entry(cmd)

    if cmd.callback then
      cmd.callback()
      return
    end

    -- some workaround not really sure if its needed at this point
    -- used to make cmds "<Cmd>do things<CR>" work
    if cmd.rhs:find("<Cmd>") then
      local parsed_rhs = Utils.clean_up_rhs(cmd.rhs)
      local parsed_cmd, args = Utils.parse_cmd_and_args(parsed_rhs)
      vim.cmd({ cmd = parsed_cmd, args = args })
    else
      local rhs = Utils.replace_term_codes(cmd.rhs)
      vim.api.nvim_feedkeys(rhs, "mit", false)
    end
  end

  local suffix = Config.suffix and (" " .. Config.suffix)
  local desc = cmd.desc .. suffix
  local opts = { nowait = true, desc = desc, noremap = cmd.noremap }
  vim.keymap.set("n", key, tracked_rhs, opts)
end

return M
