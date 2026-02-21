local tectonic = require("tectonic")
local detect = require("tectonic.detect")
local utils = require("tectonic.utils")

describe("tectonic", function()
  before_each(function()
    -- Reset state between tests
    tectonic.state.active = false
    tectonic.state.root_dir = nil
    -- Reset config to defaults
    tectonic.config = {
      auto_activate = true,
      open_index = true,
      layout = { main_file = "src/index.tex" },
      tree = { enabled = true, width = 30 },
      watcher = { auto_start = true, extra_args = {} },
      viewer = {
        enabled = true,
        app_name = "Skim",
        pdf_path = "build/default/default.pdf",
        auto_open = true,
        close_on_exit = false,
      },
    }
  end)

  describe("setup", function()
    it("uses defaults when called without args", function()
      tectonic.setup()
      assert.equals(true, tectonic.config.auto_activate)
      assert.equals("src/index.tex", tectonic.config.layout.main_file)
      assert.equals("Skim", tectonic.config.viewer.app_name)
    end)

    it("merges user config with defaults", function()
      tectonic.setup({
        viewer = { app_name = "Preview", auto_open = false },
        watcher = { extra_args = { "--bundle" } },
      })
      assert.equals("Preview", tectonic.config.viewer.app_name)
      assert.equals(false, tectonic.config.viewer.auto_open)
      -- Other defaults preserved
      assert.equals(true, tectonic.config.auto_activate)
      assert.equals("build/default/default.pdf", tectonic.config.viewer.pdf_path)
      assert.same({ "--bundle" }, tectonic.config.watcher.extra_args)
    end)

    it("preserves nested defaults not overridden", function()
      tectonic.setup({ tree = { width = 40 } })
      assert.equals(40, tectonic.config.tree.width)
      assert.equals(true, tectonic.config.tree.enabled)
    end)
  end)

  describe("detect", function()
    it("detects a tectonic project with Tectonic.toml", function()
      local tmpdir = vim.fn.tempname()
      vim.fn.mkdir(tmpdir, "p")
      vim.fn.writefile({}, tmpdir .. "/Tectonic.toml")

      assert.is_true(detect.is_tectonic_project(tmpdir))

      vim.fn.delete(tmpdir, "rf")
    end)

    it("returns false when no Tectonic.toml", function()
      local tmpdir = vim.fn.tempname()
      vim.fn.mkdir(tmpdir, "p")

      assert.is_false(detect.is_tectonic_project(tmpdir))

      vim.fn.delete(tmpdir, "rf")
    end)

    it("finds root from nested directory", function()
      local tmpdir = vim.fn.tempname()
      vim.fn.mkdir(tmpdir .. "/src", "p")
      vim.fn.writefile({}, tmpdir .. "/Tectonic.toml")

      local root = detect.find_root(tmpdir .. "/src")
      assert.equals(tmpdir, root)

      vim.fn.delete(tmpdir, "rf")
    end)

    it("returns nil when no project found", function()
      local tmpdir = vim.fn.tempname()
      vim.fn.mkdir(tmpdir, "p")

      local root = detect.find_root(tmpdir)
      assert.is_nil(root)

      vim.fn.delete(tmpdir, "rf")
    end)
  end)

  describe("state", function()
    it("starts inactive", function()
      assert.is_false(tectonic.is_active())
      assert.is_nil(tectonic.state.root_dir)
    end)
  end)

  describe("utils", function()
    it("joins paths", function()
      assert.equals("/foo/bar/baz", utils.path_join("/foo", "bar", "baz"))
      assert.equals("a/b", utils.path_join("a", "b"))
    end)

    it("checks file existence", function()
      local tmpdir = vim.fn.tempname()
      vim.fn.mkdir(tmpdir, "p")
      vim.fn.writefile({}, tmpdir .. "/test.txt")

      assert.is_true(utils.file_exists(tmpdir, "test.txt"))
      assert.is_false(utils.file_exists(tmpdir, "nonexistent.txt"))

      vim.fn.delete(tmpdir, "rf")
    end)
  end)
end)
