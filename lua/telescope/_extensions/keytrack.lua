local ok, telescope = pcall(require, "telescope")

if not ok then
  error("keytrack.nvim requires telescope as a dependency")
end

local actions = require("telescope.actions")
local entry_display = require("telescope.pickers.entry_display")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values

local keys = require("keytrack.keys")

local function new_finder()
  local cmds = keys.active_cmds

  local results = {}

  for _, val in pairs(cmds) do
    table.insert(results, { val.lhs, val.count, val.desc })
  end

  return finders.new_table({
    results = results,
    entry_maker = function(entry)
      local line = string.format("%s - %s", entry[1], entry[3])

      local displayer = entry_display.create({
        separator = " - ",
        items = {
          { width = 4 },
          { remaining = true },
        },
      })

      local display = function()
        return displayer({
          entry[2],
          line,
        })
      end

      return {
        value = entry,
        display = display,
        ordinal = line,
      }
    end,
  })
end

local function handle_telescope_plugin(opts)
  opts = opts or {}

  pickers
    .new(opts, {
      prompt_title = "Key Track",
      finder = new_finder(),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
        end)
        return true
      end,
    })
    :find()
end

return telescope.register_extension({
  exports = {
    keytrack = handle_telescope_plugin,
  },
})
