local Commands = require("keytrack.commands")
local Config = require("keytrack.config")
local Keys = require("keytrack.keys")
local UI = require("keytrack.ui")

---@class KeyTrack
local M = {}

---KeyTrack Setup
---@param user_config Config
M.setup = function(user_config)
  Config.setup(user_config)

  Keys.load_file()

  Commands.setup_autocommands()
end

M.open_window = function()
  UI.open()
end

M.close_window = function()
  UI.close()
end

---@param cmd {key: string, desc: string}
M.register = function(cmd)
  Commands.register_cmd(cmd)
end

return M
