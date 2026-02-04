-- ============================================================================
-- NEOVIM CONFIGURATION
-- ============================================================================
-- Modern Neovim setup with native LSP, Treesitter, and Lua-based plugins.
-- Migrated from Vim configuration with equivalent functionality.
--
-- Structure:
--   init.lua           - This file (entry point)
--   lua/config/        - Core configuration
--     options.lua      - Editor settings
--     keymaps.lua      - Key mappings
--     autocmds.lua     - Autocommands
--   lua/plugins/       - Plugin configurations (lazy.nvim)
--
-- LEADER KEY: \ (backslash) - same as Vim config
-- ============================================================================

-- Set leader key before loading plugins
vim.g.mapleader = "\\"
vim.g.maplocalleader = "\\"

-- Load core configuration
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- Bootstrap lazy.nvim plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Load plugins
require("lazy").setup("plugins", {
  defaults = {
    lazy = false, -- Load plugins immediately by default
  },
  install = {
    colorscheme = { "gruvbox" },
  },
  checker = {
    enabled = false, -- Don't auto-check for updates
  },
  change_detection = {
    notify = false, -- Don't notify on config changes
  },
})
