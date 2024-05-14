local Config = require("keytrack.config")
local Keys = require("keytrack.keys")
local Utils = require("keytrack.util")

local namespace = "KeyTrack"

local M = {}

---@type Command[]
M.cmds_cache = {}

M.setup = function()
  M.cmds_cache = Utils.get_all_commands("m")

  M.setup_autocommands()
end

M.setup_autocommands = function()
  local au_group = vim.api.nvim_create_augroup(namespace, {})

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
      Keys.save_to_file()
    end),
    desc = "Save trackers to file",
  })
end

M.remove_autocommands = function()
  vim.api.nvim_del_augroup_by_name(namespace)
end

---Stores the original commands to revert back to normal
---@type Command[]
M.original_cmds = {}

---Remove trackers and re-register them
M.check_trackers = function()
  M.remove_all_trackers()
  M.register_all_trackers()
end

---Register multiple triggers
M.register_all_trackers = function()
  for _, tracker in ipairs(Config.config.active) do
    M.register_cmd(tracker)
  end
end

---Remove all trackers
M.remove_all_trackers = function()
  for _, trigger in ipairs(Config.config.active) do
    M.remove_cmd(trigger.key)
  end

  ---Get all commands again
  M.cmds_cache = Utils.get_all_commands("n")
end

---@param key string
M.remove_cmd = function(key)
  key = Utils.replace_term_codes(key)
  key = Utils.keytrans(key)

  if M.original_cmds[key] then
    local original_cmd = M.original_cmds[key]
    pcall(vim.keymap.del, "n", key, {})

    local rhs = original_cmd.rhs or original_cmd.callback or ""

    local desc = original_cmd.desc or ""
    local opts = { desc = desc, noremap = original_cmd.noremap }
    pcall(vim.keymap.set, "n", key, rhs, opts)

    M.original_cmds[key] = nil
  end
end

---Register a single tracker
---@param command {key: string, desc: string}
M.register_cmd = function(command)
  local key = Utils.replace_term_codes(command.key)
  key = Utils.keytrans(key)

  ---if the command is not an actual command do not register
  local cmd = M.cmds_cache[key]
  if cmd == nil then
    ---TODO: handle this error in a different way
    -- error("Command with key " .. command.key .. " is set through vim")
    return
  end

  -- save command
  M.original_cmds[key] = cmd
  Keys.add_entry(cmd)

  local tracked_rhs = function()
    -- handle tracking
    Keys.increment_cmd(cmd)

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

  local suffix = Config.config.suffix and (" " .. Config.config.suffix)
  local desc = cmd.desc .. suffix
  local opts = { nowait = true, desc = desc, noremap = cmd.noremap }
  vim.keymap.set("n", key, tracked_rhs, opts)
end

return M
