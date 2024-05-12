# Key Tracker

Delete those unused keybinds by tracking which ones you use.

## Table of Contents

<!--toc:start-->
- [Key Tracker](#key-tracker)
  - [Table of Contents](#table-of-contents)
  - [Why](#why)
  - [Installation](#installation)
  - [Basic Setup](#basic-setup)
  - [TODO](#todo)
<!--toc:end-->

## Why

1. You're most likely a beginner or a long time Neovim user and wants to clean up their keymaps.
2. Track keymap to see how often you use them.

Mainly built to track how often I use my keymaps. In the end, I want to either delete or remap certain keymaps that I don't use often.

## Installation

- Neovim 0.8.0+

```lua
{
    "dougrocha/keytrack.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
    }
}
```

## Basic Setup

Currently, you have to opt-in for each keymap you want to track.

```lua
{
    "dougrocha/keytrack.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
    }
    opts = {
      active = {
        { key = "<leader>a", desc = "Add harpoon file" },
        { key = "<leader>sf", desc = "Search Files with telescope" },
      },
      --- Adds a suffix to the command description so you know it's being tracked
      suffix = "(Tracked)"
    },
}
```

## TODO and things I want to learn with this project

- Logger
- Telescope plugin
- Testing plugin
- Automatically active commands and not mess up all your keymaps
