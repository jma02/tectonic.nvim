local utils = require("tectonic.utils")

local M = {}

--- Set up the editor layout: open main file, open nvim-tree, return focus to editor.
---@param root_dir string
---@param config TectonicConfig
function M.setup(root_dir, config)
  -- Open main file if configured
  if config.open_index then
    local main_file = utils.path_join(root_dir, config.layout.main_file)
    if vim.fn.filereadable(main_file) == 1 then
      -- Wipe the directory buffer that opens when nvim is started with a directory
      local cur_buf = vim.api.nvim_get_current_buf()
      if vim.bo[cur_buf].buftype == "nofile" or vim.fn.isdirectory(vim.api.nvim_buf_get_name(cur_buf)) == 1 then
        vim.cmd("edit " .. vim.fn.fnameescape(main_file))
        -- Delete the old directory buffer if it's still around
        if vim.api.nvim_buf_is_valid(cur_buf) and cur_buf ~= vim.api.nvim_get_current_buf() then
          pcall(vim.api.nvim_buf_delete, cur_buf, { force = true })
        end
      else
        vim.cmd("edit " .. vim.fn.fnameescape(main_file))
      end
    else
      utils.warn("Main file not found: " .. config.layout.main_file)
    end
  end

  -- Open nvim-tree if enabled
  if config.tree.enabled then
    M._open_tree(config)
  end
end

--- Open nvim-tree.
---@param config TectonicConfig
function M._open_tree(config)
  local tree_api = require("nvim-tree.api")
  tree_api.tree.open()

  -- Return focus to the editor window (nvim-tree opens and takes focus)
  vim.cmd("wincmd l")
end

--- Toggle nvim-tree.
function M.toggle_tree()
  local tree_api = require("nvim-tree.api")
  tree_api.tree.toggle()
end

return M
