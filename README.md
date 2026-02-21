# tectonic.nvim

An Overleaf-like experience for [Tectonic](https://tectonic-typesetting.github.io/) in Neovim.

Auto-detects Tectonic projects, sets up a file tree + editor layout, runs continuous compilation, and opens a live PDF preview in Skim.

## Features

- Auto-detects Tectonic projects via `Tectonic.toml`
- File tree sidebar via nvim-tree
- Continuous compilation with `tectonic -X watch`
- Live PDF preview in Skim (macOS)
- Graceful degradation when optional dependencies are missing

## Requirements

- Neovim >= 0.8.0
- [tectonic](https://tectonic-typesetting.github.io/) — Rust-based LaTeX build system

### Optional

- [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua) — file tree sidebar
- [Skim](https://skim-app.sourceforge.io/) — PDF viewer with auto-reload (macOS)

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "jma2/tectonic.nvim",
  opts = {},
}
```

## Configuration

```lua
require("tectonic").setup({
  auto_activate = true,        -- auto-detect on VimEnter
  open_index = true,           -- open main .tex file on activation
  layout = {
    main_file = "src/index.tex",
  },
  tree = {
    enabled = true,
    width = 30,
  },
  watcher = {
    auto_start = true,
    extra_args = {},           -- additional args to tectonic -X watch
  },
  viewer = {
    enabled = true,
    app_name = "Skim",
    pdf_path = "build/default/default.pdf",
    auto_open = true,
    close_on_exit = false,
  },
})
```

## Commands

| Command | Description |
|---|---|
| `:TectonicActivate` | Manually activate the plugin |
| `:TectonicWatch` | Start watch mode |
| `:TectonicWatchStop` | Stop watch mode |
| `:TectonicWatchRestart` | Restart watch mode |
| `:TectonicOpenPDF` | Open PDF in Skim |
| `:TectonicClosePDF` | Close PDF document in Skim |
| `:TectonicFocusPDF` | Bring Skim to foreground |
| `:TectonicToggleTree` | Toggle nvim-tree |
| `:TectonicLog` | Show build log in scratch buffer |

## Suggested Keybindings

```lua
vim.keymap.set("n", "<leader>tw", "<cmd>TectonicWatch<cr>", { desc = "Start tectonic watch" })
vim.keymap.set("n", "<leader>ts", "<cmd>TectonicWatchStop<cr>", { desc = "Stop tectonic watch" })
vim.keymap.set("n", "<leader>tp", "<cmd>TectonicOpenPDF<cr>", { desc = "Open PDF" })
vim.keymap.set("n", "<leader>tt", "<cmd>TectonicToggleTree<cr>", { desc = "Toggle file tree" })
vim.keymap.set("n", "<leader>tl", "<cmd>TectonicLog<cr>", { desc = "Show build log" })
```

## Health Check

Run `:checkhealth tectonic` to verify your setup.
