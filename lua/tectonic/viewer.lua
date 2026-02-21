local utils = require("tectonic.utils")

local M = {}

-- On Linux, track the zathura process directly.
-- On macOS, `open` exits immediately so we check Skim via AppleScript.
local state = {
  job_id = nil, -- Linux only: zathura process
}

--- Check if the viewer is already showing the PDF.
---@param pdf_path string
---@param config TectonicConfig
---@param callback fun(open: boolean)
local function check_open(pdf_path, config, callback)
  if vim.fn.has("mac") == 1 then
    local abs_path = vim.fn.fnamemodify(pdf_path, ":p")
    local script = ([[
      tell application "System Events"
        if not (exists process "%s") then return "no"
      end tell
      tell application "%s"
        repeat with doc in every document
          if (POSIX path of (file of doc as alias)) is "%s" then return "yes"
        end repeat
      end tell
      return "no"
    ]]):format(config.viewer.app_name, config.viewer.app_name, abs_path)

    vim.fn.jobstart({ "osascript", "-e", script }, {
      stdout_buffered = true,
      on_stdout = function(_, data)
        local result = (data[1] or ""):match("yes")
        vim.schedule(function()
          callback(result ~= nil)
        end)
      end,
    })
  else
    callback(state.job_id ~= nil)
  end
end

--- Open a PDF in the platform viewer (Skim on macOS, zathura on Linux).
--- No-op if the viewer is already showing the document.
---@param pdf_path string
---@param config TectonicConfig
function M.open(pdf_path, config)
  check_open(pdf_path, config, function(already_open)
    if already_open then
      return
    end
    M._launch(pdf_path, config)
  end)
end

--- Launch the viewer unconditionally.
---@param pdf_path string
---@param config TectonicConfig
function M._launch(pdf_path, config)
  local cmd
  if vim.fn.has("mac") == 1 then
    cmd = { "open", "-g", "-a", config.viewer.app_name, pdf_path }
  elseif vim.fn.has("linux") == 1 then
    cmd = { config.viewer.app_name, pdf_path }
  else
    utils.warn("Unsupported platform — viewer requires macOS or Linux")
    return
  end

  local job_id = vim.fn.jobstart(cmd, {
    detach = true,
    on_exit = function(_, code)
      if state.job_id == job_id then
        state.job_id = nil
      end
      if code ~= 0 then
        utils.warn("Failed to open PDF (exit code " .. code .. ")")
      end
    end,
  })

  if job_id > 0 and vim.fn.has("linux") == 1 then
    state.job_id = job_id
  end
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
