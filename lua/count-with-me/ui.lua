local Tracker = require("count-with-me.tracker")

local M = {}

---@class UI
---@field win_id number|nil
---@field buf_id number|nil
M.ui = {}

---Create window
---@return number win_id
---@return number buf_id
M.create_window = function()
  local height = 10
  local width = 50

  local row = math.floor(((vim.o.lines - height) / 2) - 1)
  local col = math.floor((vim.o.columns - width) / 2)

  local buf_id = vim.api.nvim_create_buf(false, true)
  local win_id = vim.api.nvim_open_win(buf_id, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "single",
    title = "Count with me",
    title_pos = "left",
  })

  if win_id == 0 then
    error("unable to create window")
  end

  M.ui.buf_id = buf_id
  M.ui.win_id = win_id

  vim.api.nvim_set_option_value("scrolloff", 2, { win = win_id })
  vim.api.nvim_set_option_value("filetype", "count-with-me", {
    buf = buf_id,
  })
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf_id })

  vim.api.nvim_buf_set_keymap(buf_id, "n", "<Esc>", "", { silent = true, callback = M.close })
  vim.api.nvim_buf_set_keymap(buf_id, "n", "q", "", { silent = true, callback = M.close })

  return win_id, buf_id
end

M.open = function()
  local _, buf_id = M.create_window()

  ---@type string[]
  local data = {}

  for _, cmd in pairs(Tracker.cached_tracked) do
    local lhs = cmd.lhs
    local count = cmd.count
    local desc = cmd.desc

    local line = string.format("%s - %d: %s", lhs, count, desc)
    table.insert(data, line)
  end

  vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, data)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf_id })
  vim.api.nvim_set_option_value("readonly", true, { buf = buf_id })
end

M.close = function()
  local ui = M.ui

  if ui.buf_id ~= nil and vim.api.nvim_buf_is_valid(ui.buf_id) then
    vim.api.nvim_buf_delete(ui.buf_id, { force = true })
  end

  if ui.win_id ~= nil and vim.api.nvim_win_is_valid(ui.win_id) then
    vim.api.nvim_win_close(ui.win_id, true)
  end

  ui.buf_id = nil
  ui.win_id = nil
end

return M
