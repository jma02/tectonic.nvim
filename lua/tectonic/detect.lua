local M = {}

--- Check if a directory contains a Tectonic.toml file.
---@param dir string
---@return boolean
function M.is_tectonic_project(dir)
  return vim.fn.filereadable(dir .. "/Tectonic.toml") == 1
end

--- Find the tectonic project root by walking up from a starting directory.
---@param start_dir? string defaults to cwd
---@return string|nil root_dir
function M.find_root(start_dir)
  local dir = start_dir or vim.fn.getcwd()
  while dir and dir ~= "/" do
    if M.is_tectonic_project(dir) then
      return dir
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end
  return nil
end

return M
