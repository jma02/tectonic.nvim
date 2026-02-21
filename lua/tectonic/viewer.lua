local utils = require("tectonic.utils")

local M = {}

--- Open a PDF in the platform viewer (Skim on macOS, zathura on Linux).
---@param pdf_path string
---@param config TectonicConfig
function M.open(pdf_path, config)
  local cmd
  if vim.fn.has("mac") == 1 then
    cmd = { "open", "-g", "-a", config.viewer.app_name, pdf_path }
  elseif vim.fn.has("linux") == 1 then
    cmd = { config.viewer.app_name, pdf_path }
  else
    utils.warn("Unsupported platform — viewer requires macOS or Linux")
    return
  end

  vim.fn.jobstart(cmd, {
    detach = true,
    on_exit = function(_, code)
      if code ~= 0 then
        utils.warn("Failed to open PDF (exit code " .. code .. ")")
      end
    end,
  })
end

--- Close a specific PDF document in Skim via AppleScript (macOS only).
---@param pdf_path string
---@param config TectonicConfig
function M.close(pdf_path, config)
  if vim.fn.has("mac") ~= 1 or config.viewer.app_name ~= "Skim" then
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
  if vim.fn.has("mac") == 1 then
    vim.fn.jobstart({ "open", "-a", config.viewer.app_name })
  end
end

return M
