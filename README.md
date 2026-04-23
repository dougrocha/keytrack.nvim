<div align="center">

# Key Tracker

##### Never lose track of your keybinds

</div>

<!--toc:start-->
- [Key Tracker](#key-tracker)
  - [Why](#why)
  - [Installation](#installation)
  - [Basic Setup](#basic-setup)
  - [Usage](#usage)
<!--toc:end-->

Keytrack.nvim is a plugin made to help you keep track of how many times you
use a command/keymap. Most likely if a command you're tracking has low usage,
you can remap it or delete it to simplify your neovim config.

## Why

1. You're most likely a beginner or a long time Neovim user and wants to clean up their keymaps.
2. Track keymap to see how often you use them.

Mainly built to track how often I use my keymaps. In the end, I want to either delete or remap certain keymaps that I don't use often.

## Installation

- Neovim 0.12.0+

With `lazy.nvim`

```lua
{
    "dougrocha/keytrack.nvim",
}
```

## Basic Setup

Currently, you have to opt-in for each keymap you want to track.

```lua
{
    "dougrocha/keytrack.nvim",
    opts = {
      keymaps = {
        { key = "<leader>a", desc = "Add harpoon file" },
        { key = "<leader>sf", desc = "Search Files with telescope" },
      },
      --- (Optional) Adds a suffix to the command description so you know it's being tracked
      suffix = "(Tracked)"
    },
}
```

## Usage

Open the KeyTrack popup window:

```vim
:KeyTrack
```

The popup shows all tracked keymaps sorted by usage count. Press `q` or `<Esc>` to close.

Data is saved automatically to `$XDG_DATA_HOME/nvim/keytrack/keytrack.json` on `BufLeave` and `VimLeave`.
