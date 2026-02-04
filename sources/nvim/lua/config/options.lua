-- ============================================================================
-- NEOVIM OPTIONS
-- ============================================================================
-- Core editor settings, migrated from Vim config

local opt = vim.opt

-- ============================================================================
-- CORE SETTINGS
-- ============================================================================

-- Encoding
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"

-- Python host (ensure pynvim is available)
local python3 = vim.fn.exepath("python3")
if python3 ~= "" then
  vim.g.python3_host_prog = python3
end

-- Use system clipboard
opt.clipboard = "unnamedplus"

-- Disable bells
opt.belloff = "all"

-- ============================================================================
-- DISPLAY AND VISUAL
-- ============================================================================

-- Line numbers (hybrid mode)
opt.number = true
opt.relativenumber = true

-- Cursor and scrolling
opt.cursorline = true
opt.scrolloff = 15
opt.wrap = false
opt.sidescroll = 1
opt.sidescrolloff = 15

-- Status line
opt.laststatus = 2
opt.ruler = true
opt.showmode = false  -- Lualine shows mode

-- ============================================================================
-- SEARCH
-- ============================================================================

opt.hlsearch = true
opt.incsearch = true
opt.ignorecase = true
opt.smartcase = true
opt.showmatch = true

-- ============================================================================
-- INDENTATION
-- ============================================================================

opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true

-- ============================================================================
-- PERSISTENT UNDO
-- ============================================================================

opt.undofile = true
opt.undodir = vim.fn.expand("~/.local/share/nvim/undo//")

-- Create undo directory if it doesn't exist
local undodir = vim.fn.expand("~/.local/share/nvim/undo")
if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, "p")
end

-- ============================================================================
-- SPLITS
-- ============================================================================

opt.splitright = true
opt.splitbelow = true

-- ============================================================================
-- BUFFERS
-- ============================================================================

opt.hidden = true
opt.autoread = true

-- ============================================================================
-- COMPLETION
-- ============================================================================

opt.wildmenu = true
opt.wildmode = "full"
opt.wildignore:append({
  ".git", "tags", ".sw?",
  "*.pyc",
  "**/build/**",
  "**/node_modules/**", "**/bower_components/**", "**/dist/**",
  "package_lock.json",
  "*.jpg", "*.bmp", "*.gif", "*.png", "*.jpeg",
})

-- Better completion experience
opt.completeopt = { "menu", "menuone", "noselect" }

-- ============================================================================
-- APPEARANCE
-- ============================================================================

-- Enable 24-bit RGB colors
opt.termguicolors = true

-- Sign column always visible (prevents layout jumping)
opt.signcolumn = "yes"

-- Faster update time (for GitSigns and LSP)
opt.updatetime = 100

-- Shorter messages
opt.shortmess:append("c")
