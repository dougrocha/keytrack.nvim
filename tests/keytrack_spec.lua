---@type Config
local config = {
  active = {
    { key = "<leader>a", desc = "Add harpoon file" },
    { key = "<leader>sf", desc = "Search Files with telescope" },
  },
  suffix = "(Tracked)",
}

local setup_keymaps = function()
  pcall(function()
    vim.keymap.del("n", "<leader>wd")
    vim.keymap.del("n", "<leader>sf")
    vim.keymap.del("n", "<leader>a")
  end)

  vim.keymap.set("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })
  vim.keymap.set("n", "<leader>sf", '<Cmd>echo "testing cmd with enter"<CR>', { desc = "Search Files with telescope" })
  vim.keymap.set("n", "<leader>a", function()
    vim.echo("testing function call")
  end, {
    desc = "Add harpoon file",
  })
end

describe("keytrack", function()
  local keytrack
  local commands

  before_each(function()
    setup_keymaps()

    keytrack = require("keytrack")
    keytrack.setup(config)

    commands = require("keytrack.commands")
    commands.check_trackers()
  end)

  it("keeping track of original commands works", function()
    local expected_cmds = {
      [" a"] = {
        callback = function() end,
        desc = "Add harpoon file",
        lhs = " a",
        noremap = 1,
      },
      [" sf"] = {
        desc = "Search Files with telescope",
        lhs = " sf",
        noremap = 1,
        rhs = '<Cmd>echo "testing cmd with enter"<CR>',
      },
    }

    -- do deep copy because messing with this list, fails other tests ?!
    local actual_cmds = vim.deepcopy(commands.original_cmds)

    -- since functions cant be easily compared, set callback to nil manually
    expected_cmds[" a"].callback = nil
    actual_cmds[" a"].callback = nil

    assert.are.same(expected_cmds, actual_cmds, "expected commands do match original commands setup by registering")
  end)

  it("suffix works", function()
    local all_cmds = require("keytrack.util").get_all_commands("n")

    local harpoon_cmd = all_cmds[" a"]
    assert.are.same("Add harpoon file (Tracked)", harpoon_cmd.desc, "Suffix is not set correctly for ' a'")

    local telescope_cmd = all_cmds[" sf"]
    assert.are.same(
      "Search Files with telescope (Tracked)",
      telescope_cmd.desc,
      "Suffix is not set correctly for ' sf'"
    )
  end)
end)
