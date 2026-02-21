local M = {}

local PLUGIN_NAME = "tectonic"

--- Notify user with plugin prefix.
---@param msg string
---@param level? integer vim.log.levels value (default: INFO)
function M.notify(msg, level)
  vim.notify(("[%s] %s"):format(PLUGIN_NAME, msg), level or vim.log.levels.INFO)
end

--- Warn the user.
---@param msg string
function M.warn(msg)
  M.notify(msg, vim.log.levels.WARN)
end

--- Error notification.
---@param msg string
function M.error(msg)
  M.notify(msg, vim.log.levels.ERROR)
end

--- Check if a file exists relative to a root directory.
---@param root string
---@param relpath string
---@return boolean
function M.file_exists(root, relpath)
  local path = root .. "/" .. relpath
  return vim.fn.filereadable(path) == 1
end

--- Join path segments.
---@param ... string
---@return string
function M.path_join(...)
  return table.concat({ ... }, "/")
end

return M
