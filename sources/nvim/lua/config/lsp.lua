-- ============================================================================
-- LSP SHARED CONFIG
-- ============================================================================
-- Common diagnostics, keymaps, and capabilities shared across LSP clients.

local M = {}

function M.setup_diagnostics()
  vim.diagnostic.config({
    virtual_text = {
      prefix = "●",
    },
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = "●",
        [vim.diagnostic.severity.WARN] = "●",
        [vim.diagnostic.severity.HINT] = "●",
        [vim.diagnostic.severity.INFO] = "●",
      },
    },
    underline = false,
    update_in_insert = false,
    severity_sort = true,
  })
end

function M.on_attach(_, bufnr)
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end

  -- Navigation (same keys as Vim ALE config)
  map("n", "<leader>b", vim.lsp.buf.definition, "Go to definition")
  map("n", "<leader>r", vim.lsp.buf.references, "Find references")
  map("n", "<leader>R", vim.lsp.buf.rename, "Rename symbol")
  map("n", "<leader>a", vim.lsp.buf.code_action, "Code actions")
  map("n", "K", vim.lsp.buf.hover, "Hover documentation")

  -- Additional LSP mappings
  map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
  map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
  map("n", "<leader>D", vim.lsp.buf.type_definition, "Type definition")
  map("n", "<leader>k", vim.lsp.buf.signature_help, "Signature help")

  -- Diagnostics (similar to Vim ]e and [e)
  map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
  map("n", "[d", vim.diagnostic.goto_prev, "Previous diagnostic")
  map("n", "]e", function()
    vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
  end, "Next error")
  map("n", "[e", function()
    vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
  end, "Previous error")
  map("n", "<leader>e", vim.diagnostic.open_float, "Show diagnostic")
  map("n", "<leader>q", vim.diagnostic.setloclist, "Diagnostic list")
end

function M.capabilities()
  local ok, cmp = pcall(require, "cmp_nvim_lsp")
  if ok and cmp.default_capabilities then
    return cmp.default_capabilities()
  end
  return vim.lsp.protocol.make_client_capabilities()
end

return M
