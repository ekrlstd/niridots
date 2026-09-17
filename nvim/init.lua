vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)
vim.opt.clipboard = "unnamedplus"

local lazy_config = require "configs.lazy"

-- load plugins
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
  },

  { import = "plugins" },
}, lazy_config)

-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

-- Load theme colors from Noctalia's rendered JSON (see lua/noctalia.lua).
-- This is the replacement for the old `require("matugen").setup()` line:
-- it reads `matugen.json`, themes base46 via chadrc, applies syntax highlight
-- groups, and hot-reloads on SIGUSR1 / FocusGained. It never throws, so a
-- missing or corrupt JSON falls back to a usable palette instead of crashing.
require("noctalia").setup()

require "options"
require "autocmds"

vim.schedule(function()
  require "mappings"
end)

-- ─── Cursor shape ────────────────────────────────────────────────────────────
-- block in normal/visual/command, blinking beam in insert, block in replace.
vim.opt.guicursor = "n-v-c:block,i:ver25-blinkon500-blinkoff500,r-cr:block"

-- ─── Diagnostics ─────────────────────────────────────────────────────────────
-- Show all diagnostics (HINT and above) as inline virtual text.
-- Signs are enabled; diagnostics do not update while typing.
vim.diagnostic.config {
  virtual_text = {
    prefix = "●",
    spacing = 2,
    severity = { min = vim.diagnostic.severity.HINT },
  },
  underline = true,
  update_in_insert = false,
  signs = true,
}
