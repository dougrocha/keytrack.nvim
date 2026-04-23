local Keys = require("keytrack.keys")

local M = {}

-- Highlight groups
local HL_HEADER = "KeyTrackHeader"
local HL_KEY = "KeyTrackKey"
local HL_COUNT = "KeyTrackCount"
local HL_DESC = "KeyTrackDesc"
local HL_BORDER = "KeyTrackBorder"

local function setup_highlights()
  vim.api.nvim_set_hl(0, HL_HEADER, { link = "Title", default = true })
  vim.api.nvim_set_hl(0, HL_KEY, { link = "Keyword", default = true })
  vim.api.nvim_set_hl(0, HL_COUNT, { link = "Number", default = true })
  vim.api.nvim_set_hl(0, HL_DESC, { link = "Comment", default = true })
  vim.api.nvim_set_hl(0, HL_BORDER, { link = "FloatBorder", default = true })
end

---@class UI
---@field win_id number|nil
---@field buf_id number|nil
M.ui = {}

-- Column widths (computed at open time)
local COL_KEY = 14
local COL_COUNT = 7
-- desc fills the remainder

---Pad or truncate a string to exactly `len` characters
---@param s string
---@param len number
---@return string
local function pad(s, len)
  s = tostring(s)
  if #s >= len then
    return s:sub(1, len - 1) .. "…"
  end
  return s .. string.rep(" ", len - #s)
end

---Create window
---@return number win_id
---@return number buf_id
M.create_window = function()
  local total_w = math.floor(vim.o.columns * 0.6)
  total_w = math.max(total_w, 60)

  local total_h = math.floor(vim.o.lines * 0.5)
  total_h = math.max(total_h, 8)

  local row = math.floor((vim.o.lines - total_h) / 2) - 1
  local col = math.floor((vim.o.columns - total_w) / 2)

  local buf_id = vim.api.nvim_create_buf(false, true)
  local win_id = vim.api.nvim_open_win(buf_id, true, {
    relative = "editor",
    width = total_w,
    height = total_h,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " KeyTrack ",
    title_pos = "center",
  })

  if win_id == 0 then
    error("unable to create window")
  end

  M.ui.buf_id = buf_id
  M.ui.win_id = win_id

  vim.api.nvim_set_option_value("scrolloff", 2, { win = win_id })
  vim.api.nvim_set_option_value("cursorline", true, { win = win_id })
  vim.api.nvim_set_option_value("filetype", "keytrack", { buf = buf_id })
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf_id })

  vim.api.nvim_buf_set_keymap(buf_id, "n", "<Esc>", "", { silent = true, callback = M.close })
  vim.api.nvim_buf_set_keymap(buf_id, "n", "q", "", { silent = true, callback = M.close })

  return win_id, buf_id
end

---Apply extmark highlights to a single line
---@param buf_id number
---@param ns number
---@param line_nr number  0-indexed
---@param is_header boolean
local function highlight_line(buf_id, ns, line_nr, is_header)
  if is_header then
    vim.api.nvim_buf_add_highlight(buf_id, ns, HL_HEADER, line_nr, 0, -1)
    return
  end

  -- key column: [0, COL_KEY)
  vim.api.nvim_buf_add_highlight(buf_id, ns, HL_KEY, line_nr, 0, COL_KEY)
  -- count column: [COL_KEY, COL_KEY + COL_COUNT)
  vim.api.nvim_buf_add_highlight(buf_id, ns, HL_COUNT, line_nr, COL_KEY, COL_KEY + COL_COUNT)
  -- desc: rest of line
  vim.api.nvim_buf_add_highlight(buf_id, ns, HL_DESC, line_nr, COL_KEY + COL_COUNT, -1)
end

M.open = function()
  if M.ui.win_id ~= nil and vim.api.nvim_win_is_valid(M.ui.win_id) then
    return
  end

  setup_highlights()
  local win_id, buf_id = M.create_window()
  local win_width = vim.api.nvim_win_get_width(win_id)
  local col_desc = win_width - COL_KEY - COL_COUNT

  local sorted = {}
  for _, cmd in pairs(Keys.active_cmds) do
    table.insert(sorted, cmd)
  end
  table.sort(sorted, function(a, b)
    if a.count ~= b.count then
      return a.count > b.count
    end
    return a.lhs < b.lhs
  end)

  -- header
  local header = pad("Key", COL_KEY) .. pad("Count", COL_COUNT) .. "Description"
  local separator = string.rep("─", win_width)

  ---@type string[]
  local lines = { header, separator }

  for _, cmd in ipairs(sorted) do
    local key_col = pad(cmd.lhs, COL_KEY)
    local count_col = pad(cmd.count, COL_COUNT)
    local desc_col = pad(cmd.desc, col_desc)
    table.insert(lines, key_col .. count_col .. desc_col)
  end

  local ns = vim.api.nvim_create_namespace("keytrack_hl")
  vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)

  -- highlight header and separator
  highlight_line(buf_id, ns, 0, true)
  vim.api.nvim_buf_add_highlight(buf_id, ns, HL_BORDER, 1, 0, -1)

  -- highlight data rows
  for i = 2, #lines - 1 do
    highlight_line(buf_id, ns, i, false)
  end

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
