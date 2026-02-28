-- ============================================================================
-- NEOVIM KEY MAPPINGS
-- ============================================================================
-- Key mappings migrated from Vim config
-- Note: LSP and plugin-specific mappings are defined in their respective configs

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- ============================================================================
-- WINDOW NAVIGATION (Terminal Mode)
-- ============================================================================
-- Normal mode Ctrl+h/j/k/l handled by zellij-nav.nvim (see plugins/init.lua)
-- Mark terminal as "was in insert" before navigating away
map("t", "<C-h>", function() vim.b.terminal_insert = true; vim.cmd("stopinsert"); vim.cmd("ZellijNavigateLeft") end, opts)
map("t", "<C-j>", function() vim.b.terminal_insert = true; vim.cmd("stopinsert"); vim.cmd("ZellijNavigateDown") end, opts)
map("t", "<C-k>", function() vim.b.terminal_insert = true; vim.cmd("stopinsert"); vim.cmd("ZellijNavigateUp") end, opts)
map("t", "<C-l>", function() vim.b.terminal_insert = true; vim.cmd("stopinsert"); vim.cmd("ZellijNavigateRight") end, opts)

-- ============================================================================
-- WINDOW RESIZING (Normal Mode)
-- ============================================================================
map("n", "<leader>wh", "<C-w>_", opts)           -- Maximize height
map("n", "<leader>wv", "<C-w>|", opts)           -- Maximize width
map("n", "<leader>we", "<C-w>=", opts)           -- Equalize sizes
map("n", "<leader>wl", "20<C-w><", opts)         -- Decrease width
map("n", "<leader>wr", "20<C-w>>", opts)         -- Increase width


-- ============================================================================
-- WINDOW RESIZING (Terminal Mode)
-- ============================================================================
map("t", "<leader>wh", "<C-\\><C-n><C-w>_", opts)
map("t", "<leader>wv", "<C-\\><C-n><C-w>|", opts)
map("t", "<leader>we", "<C-\\><C-n><C-w>=", opts)
map("t", "<leader>wl", "<C-\\><C-n>20<C-w><", opts)
map("t", "<leader>wr", "<C-\\><C-n>20<C-w>>", opts)

-- ============================================================================
-- TERMINAL
-- ============================================================================
map("n", "<leader>th", ":split | terminal<CR>", opts)   -- Horizontal terminal
map("n", "<leader>tv", ":vsplit | terminal<CR>", opts)  -- Vertical terminal
map("t", "<C-[>", function() vim.b.terminal_insert = false; vim.cmd("stopinsert") end, opts) -- Exit terminal mode
map("t", "<C-v>", '<C-\\><C-n>"+pi', opts)              -- Paste in terminal

-- ============================================================================
-- SEARCH
-- ============================================================================
map("n", "<leader><space>", ":nohlsearch<CR>", opts)  -- Clear highlighting

-- ============================================================================
-- EDITING
-- ============================================================================
-- Replace word under cursor with register 0 (last yanked text)
map("n", "S", 'diw"0P', opts)

-- ============================================================================
-- QUICK REFERENCE (LSP mappings in plugins/init.lua)
-- ============================================================================
--
-- NAVIGATION (defined here)
--   Ctrl+H/J/K/L    Move between splits
--   \wh/wv/we       Window sizing
--   \th/\tv         Open terminal
--   jk              Exit terminal mode
--
-- LSP (defined in plugins/init.lua)
--   \b              Go to definition
--   \r              Find references
--   \R              Rename symbol
--   \a              Code actions
--   K               Hover documentation
--   ]d / [d         Next/previous diagnostic
--
-- TELESCOPE (defined in plugins/init.lua)
--   \f              Find files
--   ;               Find buffers
--   \g              Live grep
--
-- GIT (defined in plugins/init.lua)
--   ]h / [h         Next/previous hunk
--   \hs             Stage hunk
--   \hu             Undo hunk
--   \hp             Preview hunk
--
-- TESTS (defined in plugins/init.lua)
--   \tn             Run nearest test
--   \tf             Run test file
--   \ts             Run test suite
--   \tl             Run last test
