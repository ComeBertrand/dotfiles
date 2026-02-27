-- ============================================================================
-- NEOVIM PLUGINS (lazy.nvim)
-- ============================================================================
-- Plugin configurations organized by category
-- Migrated from Vim config with modern Lua-based alternatives

return {
  -- ==========================================================================
  -- UI: Colorscheme
  -- ==========================================================================
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    config = function()
      require("gruvbox").setup({
        contrast = "hard",
        transparent_mode = false,
      })
      vim.cmd("colorscheme gruvbox")
      vim.o.background = "dark"
    end,
  },

  -- ==========================================================================
  -- UI: Status Line (replaces lightline)
  -- ==========================================================================
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "gruvbox",
          component_separators = "|",
          section_separators = "",
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { "filename" },
          lualine_x = { "encoding", "fileformat", "filetype" },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
      })
    end,
  },

  -- ==========================================================================
  -- UI: Rainbow Brackets (replaces rainbow_parentheses)
  -- ==========================================================================
  {
    "HiPhish/rainbow-delimiters.nvim",
    config = function()
      local rainbow = require("rainbow-delimiters")
      vim.g.rainbow_delimiters = {
        strategy = {
          [""] = rainbow.strategy["global"],
        },
        query = {
          [""] = "rainbow-delimiters",
        },
      }
    end,
  },

  -- ==========================================================================
  -- UI: Icons
  -- ==========================================================================
  { "nvim-tree/nvim-web-devicons", lazy = true },

  -- ==========================================================================
  -- NAVIGATION: Telescope (replaces FZF)
  -- ==========================================================================
  {
    "nvim-telescope/telescope.nvim",
    version = "*",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
    },
    config = function()
      local telescope = require("telescope")
      local builtin = require("telescope.builtin")

      telescope.setup({
        defaults = {
          layout_strategy = "vertical",
          layout_config = {
            vertical = {
              preview_cutoff = 0,
              preview_height = 0.5,
            },
          },
          mappings = {
            i = {
              ["<C-j>"] = "move_selection_next",
              ["<C-k>"] = "move_selection_previous",
            },
          },
        },
        pickers = {
          buffers = {
            sort_mru = true,
            ignore_current_buffer = true,
          },
          find_files = {
            hidden = true,
          },
        },
      })

      pcall(telescope.load_extension, "fzf")

      -- Key mappings (same as Vim config)
      vim.keymap.set("n", "<leader>f", builtin.git_files, { desc = "Find git files" })
      vim.keymap.set("n", ";", builtin.buffers, { desc = "Find buffers" })
      vim.keymap.set("n", "<leader>g", builtin.live_grep, { desc = "Live grep" })
      vim.keymap.set("n", "<leader>F", builtin.find_files, { desc = "Find all files" })
    end,
  },

  -- ==========================================================================
  -- NAVIGATION: File Explorer (yazi)
  -- ==========================================================================
  {
    "mikavilpas/yazi.nvim",
    version = "*",
    dependencies = {
      { "nvim-lua/plenary.nvim", lazy = true },
    },
    keys = {
      { "<leader>n", "<cmd>Yazi<CR>", desc = "Open yazi at current file" },
    },
    opts = {
      open_for_directories = false,
      keymaps = {
        show_help = "<F1>",
      },
    },
  },
  {
    "yazi-rs/plugins",
    name = "yazi-plugins",
    lazy = true,
    build = function(spec)
      require("yazi.plugin").build_plugin(spec, { sub_dir = "smart-enter.yazi" })
    end,
  },

  -- ==========================================================================
  -- NAVIGATION: Code Structure (replaces tagbar)
  -- ==========================================================================
  {
    "stevearc/aerial.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("aerial").setup({
        backends = { "treesitter", "lsp" },
        layout = {
          default_direction = "right",
          min_width = 30,
        },
      })
      vim.keymap.set("n", "<leader>s", "<cmd>AerialToggle!<CR>", { desc = "Toggle code outline" })
    end,
  },

  -- ==========================================================================
  -- NAVIGATION: Tmux Integration (same as Vim)
  -- ==========================================================================
  {
    "christoomey/vim-tmux-navigator",
    init = function()
      vim.g.tmux_navigator_no_mappings = 1
    end,
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
    },
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<CR>" },
      { "<C-j>", "<cmd>TmuxNavigateDown<CR>" },
      { "<C-k>", "<cmd>TmuxNavigateUp<CR>" },
      { "<C-l>", "<cmd>TmuxNavigateRight<CR>" },
    },
  },

  -- ==========================================================================
  -- GIT: Git Signs (replaces gitgutter)
  -- ==========================================================================
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "+" },
          change = { text = "~" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
        },
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          -- Navigation (same as Vim config)
          map("n", "]h", function()
            if vim.wo.diff then return "]c" end
            vim.schedule(function() gs.next_hunk() end)
            return "<Ignore>"
          end, { expr = true, desc = "Next hunk" })

          map("n", "[h", function()
            if vim.wo.diff then return "[c" end
            vim.schedule(function() gs.prev_hunk() end)
            return "<Ignore>"
          end, { expr = true, desc = "Previous hunk" })

          -- Actions (same keys as Vim config)
          map("n", "<leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
          map("n", "<leader>hu", gs.reset_hunk, { desc = "Undo hunk" })
          map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
          map("n", "<leader>hS", gs.stage_buffer, { desc = "Stage buffer" })
          map("n", "<leader>hU", gs.reset_buffer, { desc = "Reset buffer" })
          map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, { desc = "Blame line" })
        end,
      })
    end,
  },

  -- ==========================================================================
  -- GIT: Fugitive (keeping the classic)
  -- ==========================================================================
  { "tpope/vim-fugitive" },

  -- ==========================================================================
  -- TREESITTER: Syntax Highlighting
  -- ==========================================================================
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local ok, configs = pcall(require, "nvim-treesitter.configs")
      if not ok then
        return
      end
      configs.setup({
        ensure_installed = {
          "python",
          "rust",
          "typescript",
          "tsx",
          "javascript",
          "lua",
          "vim",
          "vimdoc",
          "bash",
          "json",
          "yaml",
          "toml",
          "html",
          "css",
          "markdown",
          "markdown_inline",
          "nix",
          "latex",
        },
        sync_install = false,
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true,
        },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<CR>",
            node_incremental = "<CR>",
            scope_incremental = "<S-CR>",
            node_decremental = "<BS>",
          },
        },
      })
    end,
  },

  -- ==========================================================================
  -- LSP: Configuration
  -- ==========================================================================
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      -- LSP status updates
      { "j-hui/fidget.nvim", opts = {} },
    },
    config = function()
      local lsp = require("config.lsp")

      lsp.setup_diagnostics()

      -- Common on_attach for all LSP servers
      local on_attach = lsp.on_attach

      -- Common capabilities with nvim-cmp
      local capabilities = lsp.capabilities()

      -- Python: Pyright
      vim.lsp.config("pyright", {
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
          python = {
            analysis = {
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = "workspace",
            },
          },
        },
      })

      -- TypeScript: ts_ls
      vim.lsp.config("ts_ls", {
        on_attach = on_attach,
        capabilities = capabilities,
      })

      -- Lua: lua_ls (for Neovim config)
      vim.lsp.config("lua_ls", {
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = {
              globals = { "vim" },
            },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
            },
            telemetry = { enable = false },
          },
        },
      })

      for _, server in ipairs({ "pyright", "ts_ls", "lua_ls" }) do
        vim.lsp.enable(server)
      end
    end,
  },

  -- ==========================================================================
  -- LSP: Autocompletion
  -- ==========================================================================
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
      })

      -- Cmdline completion
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          { name = "cmdline" },
        }),
      })
    end,
  },

  -- ==========================================================================
  -- FORMATTING: Auto-format on save (replaces ALE fixers)
  -- ==========================================================================
  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          python = { "ruff_format", "ruff_fix" },
          rust = { "rustfmt" },
          typescript = { "prettier" },
          typescriptreact = { "prettier" },
          javascript = { "prettier" },
          javascriptreact = { "prettier" },
          json = { "prettier" },
          yaml = { "prettier" },
          html = { "prettier" },
          css = { "prettier" },
          lua = { "stylua" },
        },
        format_on_save = {
          timeout_ms = 500,
          lsp_fallback = true,
        },
      })
    end,
  },

  -- ==========================================================================
  -- LINTING: Additional linting (replaces ALE linters)
  -- ==========================================================================
  {
    "mfussenegger/nvim-lint",
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        python = { "ruff" },
        typescript = { "eslint" },
        typescriptreact = { "eslint" },
        javascript = { "eslint" },
        javascriptreact = { "eslint" },
      }

      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },

  -- ==========================================================================
  -- TESTING (neotest)
  -- ==========================================================================
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-neotest/nvim-nio",
      "nvim-treesitter/nvim-treesitter",
      "nvim-neotest/neotest-python",
      {
        "mrcjkb/rustaceanvim",
        init = function()
          local lsp = require("config.lsp")
          vim.g.rustaceanvim = {
            server = {
              on_attach = lsp.on_attach,
              capabilities = lsp.capabilities(),
              settings = {
                ["rust-analyzer"] = {
                  check = {
                    command = "clippy",
                  },
                  cargo = {
                    allFeatures = true,
                  },
                },
              },
            },
          }
        end,
      },
    },
    config = function()
      local neotest = require("neotest")
      neotest.setup({
        adapters = {
          require("neotest-python")({}),
          require("rustaceanvim.neotest"),
        },
      })

      -- Same mappings as Vim config
      vim.keymap.set("n", "<leader>tn", function()
        neotest.run.run()
      end, { desc = "Run nearest test" })
      vim.keymap.set("n", "<leader>tf", function()
        neotest.run.run(vim.fn.expand("%"))
      end, { desc = "Run test file" })
      vim.keymap.set("n", "<leader>ts", function()
        neotest.run.run(vim.fn.getcwd())
      end, { desc = "Run test suite" })
      vim.keymap.set("n", "<leader>tl", function()
        neotest.run.run_last()
      end, { desc = "Run last test" })
    end,
  },


  -- ==========================================================================
  -- LANGUAGE: LaTeX support
  -- ==========================================================================
  {
    "lervag/vimtex",
    ft = "tex",
  },

  -- ==========================================================================
  -- UTILITIES
  -- ==========================================================================
  -- Comment toggling
  {
    "numToStr/Comment.nvim",
    opts = {},
  },

  -- Surround text objects
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    opts = {},
  },

  -- Auto-pair brackets
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },

  -- Which-key for keybinding hints
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 500
    end,
    opts = {},
  },
}
