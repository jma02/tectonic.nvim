local utils = require("tectonic.utils")

local M = {}

local MAX_OUTPUT_LINES = 500

---@class WatcherState
local state = {
  job_id = nil,
  output = {},
}

--- Start the tectonic watcher process.
---@param root_dir string
---@param config TectonicConfig
function M.start(root_dir, config)
  if state.job_id then
    utils.warn("Watcher already running")
    return
  end

  if vim.fn.executable("tectonic") ~= 1 then
    utils.warn("tectonic not found in PATH — watcher disabled")
    return
  end

  local cmd = { "tectonic", "-X", "watch" }
  for _, arg in ipairs(config.watcher.extra_args or {}) do
    table.insert(cmd, arg)
  end

  state.output = {}

  state.job_id = vim.fn.jobstart(cmd, {
    cwd = root_dir,
    on_stdout = function(_, data)
      M._on_output(data)
    end,
    on_stderr = function(_, data)
      M._on_output(data)
    end,
    on_exit = function(_, exit_code)
      state.job_id = nil
      -- 143 = SIGTERM (normal shutdown via jobstop)
      if exit_code ~= 0 and exit_code ~= 143 then
        utils.warn("Watcher exited with code " .. exit_code)
      end
    end,
  })

  if state.job_id <= 0 then
    utils.error("Failed to start watcher")
    state.job_id = nil
    return
  end

  utils.notify("Watcher started")
end

--- Parse output and fire autocmds.
---@param data string[]
function M._on_output(data)
  for _, line in ipairs(data) do
    if line ~= "" then
      table.insert(state.output, line)

      -- Fire autocmds based on output content
      if line:match("Watching for changes") or line:match("Build complete") or line:match("Writing ") then
        vim.schedule(function()
          vim.api.nvim_exec_autocmds("User", { pattern = "TectonicBuildComplete" })
        end)
      elseif line:match("^error") or line:match("^ERROR") or line:match("fatal:") then
        vim.schedule(function()
          vim.api.nvim_exec_autocmds("User", { pattern = "TectonicBuildError" })
        end)
      elseif line:match("Rebuilding") or line:match("Running") then
        vim.schedule(function()
          vim.api.nvim_exec_autocmds("User", { pattern = "TectonicBuildStarted" })
        end)
      end
    end
  end

  -- Cap output lines
  if #state.output > MAX_OUTPUT_LINES then
    local start = #state.output - MAX_OUTPUT_LINES + 1
    state.output = vim.list_slice(state.output, start, #state.output)
  end
end

--- Stop the watcher process.
function M.stop()
  if not state.job_id then
    return
  end

  vim.fn.jobstop(state.job_id)
  state.job_id = nil
  utils.notify("Watcher stopped")
end

--- Restart the watcher.
---@param root_dir string
---@param config TectonicConfig
function M.restart(root_dir, config)
  M.stop()
  M.start(root_dir, config)
end

--- Check if the watcher is running.
---@return boolean
function M.is_running()
  return state.job_id ~= nil
end

--- Get captured output lines.
---@return string[]
function M.get_output()
  return vim.list_slice(state.output, 1, #state.output)
end

return M
