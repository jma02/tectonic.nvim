local utils = require("tectonic.utils")
local detect = require("tectonic.detect")
local watcher = require("tectonic.watcher")
local viewer = require("tectonic.viewer")
local layout = require("tectonic.layout")

local M = {}

---@class TectonicConfig
M.config = {
  auto_activate = true,
  open_index = true,
  layout = { main_file = "src/index.tex" },
  tree = { enabled = true, width = 30 },
  watcher = { auto_start = true, extra_args = {} },
  viewer = {
    enabled = true,
    app_name = vim.fn.has("mac") == 1 and "Skim" or "zathura",
    pdf_path = "build/default/default.pdf",
    auto_open = true,
    close_on_exit = false,
  },
}

---@class TectonicState
M.state = {
  active = false,
  root_dir = nil,
  log_buf = nil,
}

--- Merge user options with defaults.
---@param opts? table
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

--- Activate the plugin for a tectonic project.
---@param root_dir string
function M.activate(root_dir)
  if M.state.active then
    utils.warn("Already active for " .. M.state.root_dir)
    return
  end

  M.state.active = true
  M.state.root_dir = root_dir
  utils.notify("Activated for " .. root_dir)

  -- Layout: open main file + tree
  layout.setup(root_dir, M.config)

  -- Watcher: start continuous compilation
  if M.config.watcher.auto_start then
    watcher.start(root_dir, M.config)
  end

  -- Auto-open log on error, close on success
  local log_group = vim.api.nvim_create_augroup("TectonicAutoLog", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = log_group,
    pattern = "TectonicBuildError",
    callback = function()
      M.show_log()
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = log_group,
    pattern = "TectonicBuildComplete",
    callback = function()
      M.close_log()
    end,
  })

  -- Viewer: open PDF
  if M.config.viewer.enabled and M.config.viewer.auto_open then
    local pdf = utils.path_join(root_dir, M.config.viewer.pdf_path)
    if vim.fn.filereadable(pdf) == 1 then
      viewer.open(pdf, M.config)
    else
      -- Defer until first build completes
      local group = vim.api.nvim_create_augroup("TectonicViewerDeferred", { clear = true })
      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "TectonicBuildComplete",
        once = true,
        callback = function()
          local deferred_pdf = utils.path_join(root_dir, M.config.viewer.pdf_path)
          if vim.fn.filereadable(deferred_pdf) == 1 then
            viewer.open(deferred_pdf, M.config)
          end
        end,
      })
    end
  end
end

--- Stop watcher and close viewer.
function M.cleanup()
  if not M.state.active then
    return
  end

  watcher.stop()

  if M.config.viewer.close_on_exit and M.state.root_dir then
    local pdf = utils.path_join(M.state.root_dir, M.config.viewer.pdf_path)
    viewer.close(pdf, M.config)
  end

  M.state.active = false
  M.state.root_dir = nil
end

--- Check if currently active.
---@return boolean
function M.is_active()
  return M.state.active
end

--- Try auto-detection from cwd.
function M.try_auto_activate()
  if not M.config.auto_activate then
    return
  end

  local cwd = vim.fn.getcwd()
  if detect.is_tectonic_project(cwd) then
    vim.defer_fn(function()
      M.activate(cwd)
    end, 50)
  end
end

--- Show build log in a scratch buffer. Reuses existing log buffer if open.
function M.show_log()
  local lines = watcher.get_output()
  if #lines == 0 then
    utils.notify("No build output available")
    return
  end

  -- Reuse existing log buffer if it's still valid
  local buf = M.state.log_buf
  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    -- Ensure it's visible in some window
    local wins = vim.fn.win_findbuf(buf)
    if #wins == 0 then
      local prev_win = vim.api.nvim_get_current_win()
      vim.cmd("botright split")
      vim.api.nvim_win_set_buf(0, buf)
      vim.api.nvim_set_current_win(prev_win)
    end
    return
  end

  local prev_win = vim.api.nvim_get_current_win()
  vim.cmd("botright new")
  buf = vim.api.nvim_get_current_buf()
  M.state.log_buf = buf
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "tectonic-log"
  vim.api.nvim_buf_set_name(buf, "Tectonic Log")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.api.nvim_set_current_win(prev_win)

  -- Clear our reference when the buffer is wiped
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    once = true,
    callback = function()
      M.state.log_buf = nil
    end,
  })
end

--- Close the log buffer if it's open.
function M.close_log()
  local buf = M.state.log_buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  -- Close all windows showing this buffer
  local wins = vim.fn.win_findbuf(buf)
  for _, win in ipairs(wins) do
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
end

return M
