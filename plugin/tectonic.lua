if vim.g.loaded_tectonic then
  return
end
vim.g.loaded_tectonic = true

local tectonic = require("tectonic")
local watcher = require("tectonic.watcher")
local viewer = require("tectonic.viewer")
local layout = require("tectonic.layout")
local utils = require("tectonic.utils")

-- Auto-detect on VimEnter
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("TectonicAutoDetect", { clear = true }),
  callback = function()
    tectonic.try_auto_activate()
  end,
})

-- Cleanup on exit
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("TectonicCleanup", { clear = true }),
  callback = function()
    tectonic.cleanup()
  end,
})

-- User commands
vim.api.nvim_create_user_command("TectonicActivate", function()
  local detect = require("tectonic.detect")
  local root = detect.find_root()
  if root then
    tectonic.activate(root)
  else
    utils.error("No Tectonic.toml found in current directory or parents")
  end
end, { desc = "Activate tectonic.nvim" })

vim.api.nvim_create_user_command("TectonicWatch", function()
  if not tectonic.is_active() then
    utils.error("Not in an active tectonic project — run :TectonicActivate first")
    return
  end
  watcher.start(tectonic.state.root_dir, tectonic.config)
end, { desc = "Start tectonic watch mode" })

vim.api.nvim_create_user_command("TectonicWatchStop", function()
  watcher.stop()
end, { desc = "Stop tectonic watch mode" })

vim.api.nvim_create_user_command("TectonicWatchRestart", function()
  if not tectonic.is_active() then
    utils.error("Not in an active tectonic project")
    return
  end
  watcher.restart(tectonic.state.root_dir, tectonic.config)
end, { desc = "Restart tectonic watch mode" })

vim.api.nvim_create_user_command("TectonicOpenPDF", function()
  if not tectonic.is_active() then
    utils.error("Not in an active tectonic project")
    return
  end
  local pdf = utils.path_join(tectonic.state.root_dir, tectonic.config.viewer.pdf_path)
  viewer.open(pdf, tectonic.config)
end, { desc = "Open PDF in viewer" })

vim.api.nvim_create_user_command("TectonicClosePDF", function()
  if not tectonic.is_active() then
    utils.error("Not in an active tectonic project")
    return
  end
  local pdf = utils.path_join(tectonic.state.root_dir, tectonic.config.viewer.pdf_path)
  viewer.close(pdf, tectonic.config)
end, { desc = "Close PDF document in viewer" })

vim.api.nvim_create_user_command("TectonicFocusPDF", function()
  viewer.focus(tectonic.config)
end, { desc = "Bring PDF viewer to foreground" })

vim.api.nvim_create_user_command("TectonicToggleTree", function()
  layout.toggle_tree()
end, { desc = "Toggle nvim-tree file explorer" })

vim.api.nvim_create_user_command("TectonicLog", function()
  tectonic.show_log()
end, { desc = "Show tectonic build log" })
