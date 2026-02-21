local M = {}

function M.check()
  vim.health.start("tectonic.nvim")

  -- Check tectonic binary
  if vim.fn.executable("tectonic") == 1 then
    local handle = io.popen("tectonic --version 2>&1")
    local version = handle and handle:read("*l") or "unknown"
    if handle then
      handle:close()
    end
    vim.health.ok("tectonic found: " .. version)
  else
    vim.health.warn("tectonic not found in PATH")
  end

  -- Check Skim (macOS only)
  if vim.fn.has("mac") == 1 then
    if vim.fn.isdirectory("/Applications/Skim.app") == 1 then
      vim.health.ok("Skim.app found")
    else
      vim.health.warn("Skim.app not found in /Applications")
    end
  else
    vim.health.info("Skim check skipped (not macOS)")
  end

  -- Check nvim-tree
  local ok, _ = pcall(require, "nvim-tree")
  if ok then
    vim.health.ok("nvim-tree is installed")
  else
    vim.health.error("nvim-tree not installed (required)")
  end

  -- Check Tectonic.toml in cwd
  local cwd = vim.fn.getcwd()
  if vim.fn.filereadable(cwd .. "/Tectonic.toml") == 1 then
    vim.health.ok("Tectonic.toml found in " .. cwd)
  else
    vim.health.info("No Tectonic.toml in current directory")
  end
end

return M
