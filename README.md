# Workspaces Enhancer Nvim

This plug-in is an enhancement of [workspace.nvim](https://github.com/natecraddock/workspaces.nvim). It can automatically record and open the buffer of the last access of the current workspace, and it supports opening multiple workspaces. When you enter the buffer of different workspaces, the plug-in will automatically switch cwd to the workspace of entered buffer.

# Installation

If you use packer.

```lua
use("fengwk/my-utils.nvim") -- My toolkit just doesn't want to copy the same code in multiple repo
use("natecraddock/workspaces.nvim")
use("fengwk/workspaces-enhancer.nvim")
```

# Usage

This is my configuration, which can be used as a reference. If you want use telescope picker, you should config telescope extension [telescope-picker](https://github.com/natecraddock/workspaces.nvim#telescope-picker).

```lua
local ok, ws_enhancer = pcall(require, "workspaces-enhancer")
if not ok then
  vim.notify("Workspaces enhancer can not be required.")
end

ws_enhancer.setup({
  -- to change directory for all of nvim (:cd) or only for the current window (:lcd)
  -- if you are unsure, you likely want this to be true.
  global_cd = true,

  -- sort the list of workspaces by name after loading from the workspaces path.
  sort = true,

  -- sort by recent use rather than by name. requires sort to be true
  mru_sort = true,

  -- enable info-level notifications after adding or removing a workspace
  notify_info = true,
})

-- You need to config telescope extension before using this mapping.
vim.keymap.set("n", "<leader>fs", "<Cmd>Telescope workspaces theme=dropdown<CR>", { noremap = true, silent = true, desc = "Load Workspaces" })
```
