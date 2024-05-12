vim.keymap.set("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })
vim.keymap.set("n", "<leader>sf", '<Cmd>echo "testing cmd with enter"<CR>', { desc = "Search Files with telescope" })
vim.keymap.set("n", "<leader>a", "", {
  callback = function()
    vim.echo("testing function call")
  end,
  desc = "Add harpoon file",
})

---@type KeyTrackConfig
local default_config = {
  active = {
    { key = "<leader>a", desc = "Add harpoon file" },
    { key = "<leader>sf", desc = "Search Files with telescope" },
    { key = "<leader>wd", desc = "Delete Window" },
  },
  suffix = "(Tracked)",
}

describe("keytrack", function()
  it("setup with config works", function()
    local keytrack = require("keytrack")
    keytrack.setup(default_config)
  end)

  it("suffix works", function()
    local keytrack = require("keytrack")
    keytrack.setup(default_config)
    keytrack.register_all_trackers()

    local cmds = require("keytrack.util").get_all_commands("n")
    local sf_cmd = cmds[" sf"]

    local expected_desc = "Search Files with telescope (Tracked)"
    assert.are.same(expected_desc, sf_cmd.desc, "Suffix is not set correctly")
  end)
end)
