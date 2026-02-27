-- ============================================================================
-- NEOVIM AUTOCOMMANDS
-- ============================================================================
-- Autocommands migrated from Vim config

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- ============================================================================
-- FILETYPE: Plain Text
-- ============================================================================
augroup("ft_text", { clear = true })
autocmd("FileType", {
  group = "ft_text",
  pattern = "txt",
  callback = function()
    vim.opt_local.colorcolumn = "80"
    vim.opt_local.textwidth = 80
  end,
})

-- ============================================================================
-- FILETYPE: Python
-- ============================================================================
augroup("ft_python", { clear = true })

-- Folding and formatting
autocmd("FileType", {
  group = "ft_python",
  pattern = "python",
  callback = function()
    vim.opt_local.foldmethod = "indent"
    vim.opt_local.foldenable = false
    vim.opt_local.foldcolumn = "0"
    vim.opt_local.foldnestmax = 10
    vim.opt_local.foldlevel = 10
    vim.opt_local.colorcolumn = "120"
    vim.opt_local.textwidth = 120
  end,
})

-- Python debug breakpoint mapping (\x)
autocmd("FileType", {
  group = "ft_python",
  pattern = "python",
  callback = function()
    vim.keymap.set("n", "<leader>x", "Oimport pudb; pudb.set_trace()<Esc>", {
      buffer = true,
      noremap = true,
      silent = true,
      desc = "Insert pudb breakpoint"
    })
  end,
})

-- ============================================================================
-- FILETYPE: Rust
-- ============================================================================
augroup("ft_rust", { clear = true })

autocmd("FileType", {
  group = "ft_rust",
  pattern = "rust",
  callback = function()
    vim.opt_local.colorcolumn = "100"
  end,
})

-- ============================================================================
-- FILETYPE: TypeScript/JavaScript
-- ============================================================================
augroup("ft_typescript", { clear = true })

autocmd("FileType", {
  group = "ft_typescript",
  pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.shiftwidth = 2
  end,
})

-- ============================================================================
-- FILETYPE: Lua
-- ============================================================================
augroup("ft_lua", { clear = true })

autocmd("FileType", {
  group = "ft_lua",
  pattern = "lua",
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.shiftwidth = 2
  end,
})

-- ============================================================================
-- GENERAL: Auto-reload files changed outside Neovim
-- ============================================================================
augroup("auto_reload", { clear = true })

autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  group = "auto_reload",
  pattern = "*",
  callback = function()
    -- Avoid command-line window and cmdline mode.
    if vim.fn.getcmdwintype() ~= "" or vim.fn.mode() == "c" then
      return
    end
    pcall(vim.cmd, "checktime")
  end,
})

-- ============================================================================
-- GENERAL: Highlight on yank
-- ============================================================================
augroup("highlight_yank", { clear = true })

autocmd("TextYankPost", {
  group = "highlight_yank",
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- ============================================================================
-- GENERAL: Restore cursor position
-- ============================================================================
augroup("restore_cursor", { clear = true })

autocmd("BufReadPost", {
  group = "restore_cursor",
  pattern = "*",
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local line_count = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- ============================================================================
-- TERMINAL: Preserve insert/normal mode across buffer switches
-- ============================================================================
augroup("terminal_settings", { clear = true })

autocmd("TermOpen", {
  group = "terminal_settings",
  pattern = "*",
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.buflisted = false
    vim.b.terminal_insert = true
    vim.cmd("startinsert")
  end,
})

-- Auto-close terminal buffer when process exits
autocmd("TermClose", {
  group = "terminal_settings",
  pattern = "*",
  callback = function(ev)
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(ev.buf) then
        vim.api.nvim_buf_delete(ev.buf, { force = true })
      end
    end)
  end,
})

-- Track when user manually re-enters terminal mode (i/a/etc)
autocmd("TermEnter", {
  group = "terminal_settings",
  pattern = "*",
  callback = function()
    vim.b.terminal_insert = true
  end,
})

-- Restore terminal mode when switching back to a terminal window
autocmd({ "BufEnter", "WinEnter" }, {
  group = "terminal_settings",
  pattern = "term://*",
  callback = function()
    if vim.b.terminal_insert then
      vim.schedule(function()
        if vim.bo.buftype == "terminal" and vim.b.terminal_insert then
          vim.cmd("startinsert")
        end
      end)
    end
  end,
})


-- ============================================================================
-- ZELLIJ: Unlock on exit
-- ============================================================================
-- When exiting Neovim inside Zellij, switch back to normal mode so autolock
-- doesn't leave Zellij stuck in locked mode.
augroup("zellij_unlock", { clear = true })

autocmd("VimLeave", {
  group = "zellij_unlock",
  pattern = "*",
  callback = function()
    if vim.env.ZELLIJ then
      vim.fn.system("zellij action switch-mode normal")
    end
  end,
})

-- ============================================================================
-- EXTRA VIM: Load additional config from $EXTRA_VIM
-- ============================================================================
-- Supports loading extra Lua/Vim config files
-- Set EXTRA_VIM to colon-separated paths
if vim.env.EXTRA_VIM then
  for path in vim.env.EXTRA_VIM:gmatch("[^:]+") do
    if path:match("%.lua$") then
      pcall(dofile, path)
    else
      pcall(vim.cmd.source, path)
    end
  end
end
