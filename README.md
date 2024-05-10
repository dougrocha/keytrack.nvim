# Nvim Count With Me

## Table of Contents

<!--toc:start-->
- [Nvim Count With Me](#nvim-count-with-me)
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
    "dougrocha/count-with-me",
    dependencies = {
        "nvim-lua/plenary.nvim",
    }
}
```

## Basic Setup

Currently, you have to opt-in for each keymap you want to track.

```lua
{
    "dougrocha/count-with-me",
    dependencies = {
        "nvim-lua/plenary.nvim",
    }
    opts = {
      active = {
        { key = "<leader>a", desc = "Add harpoon file" },
        { key = "<leader>sf", desc = "Search Files with telescope" },
        { key = "<leader>fw", desc = "Search for word under cursor" },
        { key = "<leader>/", desc = "Grep workspace" },
      },
    },
}
```

## TODO

- Logger
- Telescope plugin
