local utils = require("tectonic.utils")

local M = {}

--- Open a PDF in the configured viewer (background, no focus steal).
---@param pdf_path string
---@param config TectonicConfig
function M.open(pdf_path, config)
  local app = config.viewer.app_name

  if vim.fn.has("mac") ~= 1 then
    utils.warn("PDF viewer requires macOS (open command)")
    return
  end

  vim.fn.jobstart({ "open", "-g", "-a", app, pdf_path }, {
    on_exit = function(_, code)
      if code ~= 0 then
        utils.warn("Failed to open " .. app .. " (exit code " .. code .. ")")
      end
    end,
  })
end

--- Close a specific PDF document in Skim via AppleScript.
---@param pdf_path string
---@param config TectonicConfig
function M.close(pdf_path, config)
  local app = config.viewer.app_name
  if app ~= "Skim" then
    return
  end

  local abs_path = vim.fn.fnamemodify(pdf_path, ":p")
  local script = ([[
    tell application "Skim"
      set docList to every document
      repeat with doc in docList
        if (POSIX path of (file of doc as alias)) is "%s" then
          close doc
          exit repeat
        end if
      end repeat
    end tell
  ]]):format(abs_path)

  vim.fn.jobstart({ "osascript", "-e", script }, { detach = true })
end

--- Bring the viewer app to the foreground.
---@param config TectonicConfig
function M.focus(config)
  local app = config.viewer.app_name
  if vim.fn.has("mac") ~= 1 then
    return
  end

  vim.fn.jobstart({ "open", "-a", app }, {
    on_exit = function(_, code)
      if code ~= 0 then
        utils.warn("Failed to focus " .. app)
      end
    end,
  })
end

return M
