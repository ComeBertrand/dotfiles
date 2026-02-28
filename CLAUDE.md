# CLAUDE.md

**NixOS declarative configuration for Python/Rust/TypeScript development with i3, Vim/Neovim, and Kubernetes tooling.**

---

## Essential Commands

```bash
./recrank.sh                        # Apply configuration changes
./upgrade.sh                        # Update all packages (updates flake.lock)
nix flake update                    # Update flake inputs only
sudo nixos-rebuild switch --flake .#wiremind  # Manual flake rebuild

# Utility scripts
screenz                             # Configure monitors
startdm                             # Start X11/i3 (required - autorun disabled)
switchkb                            # Toggle US/FR keyboard
nixinit python                      # Scaffold .envrc + shell.nix for a project
```

---

## Quick Start: Making Changes

### Add a Package

```nix
# In configuration.nix - User packages (cbertrand only)
users.users.cbertrand.packages = with pkgs; [
  my-new-package
];

# System packages (all users)
environment.systemPackages = with pkgs; [
  my-system-package
];

# Unstable package (from flake input)
environment.systemPackages = with pkgs; [
  pkgs-unstable.bleeding-edge-package
];
```

Then run: `./recrank.sh`

### Add a Dotfile

```nix
# In configuration.nix - Home Manager section
home-manager.users.cbertrand.home.file = {
  ".config/myapp/config.toml" = {
    source = ./sources/myapp.toml;
  };
};
```

Create `sources/myapp.toml`, then run: `./recrank.sh`

### Add a Vim Plugin

```vim
" In sources/vimrc - Section 9 (Plugin Manager)
Plug 'author/plugin-name'  " Brief description

" Then in Section 11 (Plugin Configurations)
let g:plugin_setting = value
```

Open Vim and run: `:PlugInstall`

### Add a Neovim Plugin

```lua
-- In sources/nvim/lua/plugins/init.lua - add to the return table
{
  "author/plugin-name",
  config = function()
    require("plugin-name").setup({
      -- plugin configuration
    })
  end,
},
```

Open Neovim - lazy.nvim will auto-install on startup.

### Configure ALE for New Language (Vim)

```vim
" In sources/vimrc - ALE configuration
let g:ale_linters = {
\   'mylang': ['linter-name'],
\}

let g:ale_fixers = {
\   'mylang': ['formatter-name'],
\}
```

### Configure LSP for New Language (Neovim)

```lua
-- In sources/nvim/lua/plugins/init.lua - in the nvim-lspconfig config
lspconfig.mylang_ls.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})
```

Install LSP server/linter/formatter in `configuration.nix` packages.

---

## Git Commit Format

```bash
# Pattern: <type>: <description>

feat: add vim-test integration           # New functionality
fix: resolve ALE symbol search crash     # Bug fix
chore: update python to 3.12            # Maintenance
docs: update CLAUDE.md structure        # Documentation
refactor: reorganize vimrc sections     # Code restructuring
```

Real examples from this repo:
- `feat: add vim-test to vimrc` (a6d59ae)
- `feat: use uv as a python package manager` (8c468f3)
- `chore: remove aider stuff` (95c5510)

---

## Critical Rules (DON'T Skip These!)

1. **Commit `flake.lock`** - This file pins exact versions for reproducibility. Always commit changes to it.

2. **DON'T edit `hardware-configuration.nix`** - It's auto-generated. Regenerate with `nixos-generate-config` if needed.

3. **X11 won't autostart** - Run `startdm` manually to launch i3 window manager.

4. **DON'T use `-uall` with git status** - Can cause memory issues on large repos.

5. **Read files before editing** - Always check current state with Read tool before making changes.

6. **Test before committing** - Run `./recrank.sh` to verify NixOS config syntax.

7. **All changes are declarative** - Don't suggest imperative package installs. Everything goes through `configuration.nix`.

---

## Project Structure

```
dotfiles/
├── flake.nix                  # Flake definition (inputs & outputs)
├── flake.lock                 # Pinned dependency versions (COMMIT THIS)
├── configuration.nix          # Main NixOS config (EDIT THIS)
├── hardware-configuration.nix # Auto-generated (DON'T EDIT)
├── recrank.sh                 # Rebuild script (flake-based)
├── upgrade.sh                 # Update script (updates flake.lock)
├── nix-work/                  # Optional work module stub (override input)
│
└── sources/                   # All dotfiles live here
    ├── vimrc                  # Vim config (fallback editor)
    ├── nvim/                  # Neovim config (primary editor)
    │   ├── init.lua           # Entry point
    │   └── lua/
    │       ├── config/        # Core settings
    │       │   ├── options.lua
    │       │   ├── keymaps.lua
    │       │   └── autocmds.lua
    │       └── plugins/       # Plugin configs (lazy.nvim)
    │           └── init.lua
    ├── bashrc.sh              # Bash interactive shell
    ├── bash_profile.sh        # Login shell init
    ├── aliases.sh             # Shell aliases
    ├── gitconfig.conf         # Git config
    ├── i3config.conf          # i3 window manager
    ├── zellij.kdl             # Zellij config
    ├── config.nix             # User nixpkgs config
    │
    └── scripts/               # Custom utilities
        ├── screenz            # Monitor configuration
        ├── startdm            # Start display manager
        ├── switchkb           # Keyboard layout toggle
        └── nixinit             # Project scaffolding (envrc + shell.nix + git excludes)
```

---

## System Details

- **User:** cbertrand
- **Hostname:** wiremind
- **NixOS:** 25.05 (+ unstable flake input for bleeding-edge)
- **Config Style:** Nix Flakes (reproducible builds via flake.lock)
- **Window Manager:** i3
- **Editor (primary):** Neovim with native LSP, Treesitter, lazy.nvim
- **Editor (fallback):** Vim with ALE (Python: ruff+pyright, Rust: rust-analyzer, TS: tsserver+eslint)
- **Shell:** Bash with direnv
- **Timezone:** Europe/Paris

---

## External Dependencies

**Optional (work-only):**
- `../nix-work` - Work-specific config (scripts auto-override `nix-work` input)

**Managed by flake.nix (no manual setup needed):**
- nixpkgs 25.05 (stable)
- nixpkgs-unstable (bleeding-edge packages)
- home-manager release-25.05

All dependencies are pinned in `flake.lock` for reproducibility.

---

## Neovim Quick Reference

**Leader key:** `\`

```lua
-- Navigation
\f              Telescope git files
;               Telescope buffers
\g              Telescope live grep
\n              Oil file explorer
\s              Aerial code outline
Ctrl+H/J/K/L    Navigate splits (zellij-aware)

-- Code Intelligence (Native LSP)
\b              Go to definition
\r              Find references
\R              Rename symbol
\a              Code actions
K               Hover documentation
]d / [d         Next/prev diagnostic
]e / [e         Next/prev error

-- Git (Gitsigns)
]h / [h         Next/prev hunk
\hs             Stage hunk
\hu             Undo hunk
\hp             Preview hunk
\hb             Blame line

-- Testing (vim-test)
\tn             Run nearest test
\tf             Run test file
\ts             Run test suite
\tl             Run last test

-- Python specific
\x              Insert pudb breakpoint

-- Plugin management
:Lazy           Open lazy.nvim UI
:Mason          Open Mason LSP installer (if needed)
```

---

## Vim Quick Reference (Fallback)

**Leader key:** `\`

```vim
" Navigation
\f              FZF file search (git files)
;               FZF buffer search
\n              Ranger file explorer
\s              Tagbar (code structure)
Ctrl+H/J/K/L    Navigate splits (zellij-aware)

" Code Intelligence (ALE)
\b              Go to definition
\r              Find references
\R              Rename symbol
\a              Symbol search
K               Hover documentation
]e / [e         Next/prev error

" Git (GitGutter)
]h / [h         Next/prev hunk
\hs             Stage hunk
\hu             Undo hunk
\hp             Preview hunk

" Testing (vim-test)
\tn             Run nearest test
\tf             Run test file
\ts             Run test suite
\tl             Run last test

" Python specific
\x              Insert pudb breakpoint
```

---

## Common Patterns

**Allow an insecure package:**
```nix
# In configuration.nix
nixpkgs.config.permittedInsecurePackages = [
  "nodejs-14.21.3"
];

# Also in sources/config.nix for user commands
{
  permittedInsecurePackages = [
    "nodejs-14.21.3"
  ];
}
```

**Add a custom script:**
```bash
# Create in sources/scripts/myscript
#!/usr/bin/env bash
echo "My script"

# Link in configuration.nix
".local/bin/myscript" = {
  source = ./sources/scripts/myscript;
  executable = true;
};
```

**NixOS version upgrade:**
```nix
# In flake.nix - update nixpkgs input URL
nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
home-manager.url = "github:nix-community/home-manager/release-25.05";
```
```bash
nix flake update
./recrank.sh
sudo reboot
```

---

## When Things Break

**Syntax error in configuration.nix or flake.nix:**
```bash
nix flake check
# Shows where syntax/evaluation errors are
```

**Rollback to previous generation:**
```bash
sudo nixos-rebuild --rollback --flake .#wiremind
# OR use boot menu to select previous generation
```

**Rollback to previous flake.lock:**
```bash
git checkout HEAD~1 -- flake.lock
./recrank.sh
```

**Neovim plugins broken:**
```vim
:Lazy restore   " Restore plugins to lockfile state
:Lazy clean     " Remove unused plugins
:Lazy sync      " Install/update plugins
```

**Neovim LSP not working:**
- Check LSP server installed in configuration.nix
- Run `:LspInfo` to see active LSP clients
- Run `:checkhealth` for diagnostics
- Check `:messages` for errors

**Vim plugins broken:**
```vim
:PlugClean      " Remove unused
:PlugInstall    " Reinstall
:PlugUpdate     " Update all
```

**ALE not working (Vim):**
- Check linter/formatter installed in configuration.nix
- Run `:ALEInfo` in Vim to see diagnostics
- Verify `g:ale_linters` and `g:ale_fixers` dictionaries

---

## Additional Documentation

For comprehensive details, see:
- **[docs/CLAUDE_COMPREHENSIVE.md](docs/CLAUDE_COMPREHENSIVE.md)** - Full system documentation
- **[README.md](README.md)** - Setup and startup manual

---

**Last Updated:** 2026-02-04
