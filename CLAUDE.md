# CLAUDE.md

**NixOS declarative configuration for Python/Rust/TypeScript development with i3, Vim/Neovim, and Kubernetes tooling.**

---

## Essential Commands

```bash
./recrank.sh                        # Apply configuration changes
./upgrade.sh                        # Update all packages (updates flake.lock)
nix flake update                    # Update flake inputs only
sudo nixos-rebuild switch --flake .#wiremind  # Manual flake rebuild

# Verify a change builds WITHOUT switching (no sudo needed)
nix build .#nixosConfigurations.wiremind.config.system.build.toplevel --no-link

# Utility scripts
screenz                             # Configure monitors
startdm                             # Start X11/i3 (required - autorun disabled)
switchkb                            # Toggle US/FR keyboard
nixinit python                      # Scaffold .envrc + shell.nix for a project
dcs                                 # Docker Compose services helper
k9                                  # Pick a process with fzf and kill it
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

### Pair a Syncthing Machine

Device IDs go in the `syncthingPeers` attrset in the `let` block at the top of
`configuration.nix` — the **only** place to edit. Devices and both folders' share
lists derive from it.

```nix
syncthingPeers = {
  laptop = "AAAAAAA-BBBBBBB-...";  # the OTHER machine's ID
};
```

```bash
# Print a machine's own ID (2.x needs --home; device-id is a subcommand):
syncthing --home=$HOME/.config/syncthing device-id
```

Then `./recrank.sh` on both ends. Folder IDs (`documents`, `workspace`) must match
across machines; local paths may differ.

`overrideDevices`/`overrideFolders` are `true`, so **anything added in the web UI
(localhost:8384) is deleted on the next rebuild** — pair in the repo, not the GUI.
This machine's own ID is recorded as a comment beside `syncthingPeers`.

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

Uses the native `vim.lsp` API (Neovim 0.11+), not `lspconfig.setup()`:

```lua
-- In sources/nvim/lua/plugins/init.lua - in the nvim-lspconfig config
vim.lsp.config("mylang_ls", {
  settings = { ... },
})

-- Then add it to the enable loop in the same file:
for _, server in ipairs({ "pyright", "ts_ls", "lua_ls", "mylang_ls" }) do
  vim.lsp.enable(server)
end
```

Shared diagnostics + on-attach keymaps live in `sources/nvim/lua/config/lsp.lua`.

Rust is deliberately absent from that list: **rustaceanvim** manages rust-analyzer
itself, so don't also declare it here.

Formatters go in conform's `formatters_by_ft`, linters in nvim-lint's `linters_by_ft`.
Install the LSP server/linter/formatter in `configuration.nix` packages.

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

1. **`git add` new files** - Flakes only evaluate **git-tracked** files. An untracked new file is invisible to the build and produces confusing "file not found" errors. This is the most common source of trouble in this repo.

2. **Commit `flake.lock`** - This file pins exact versions for reproducibility. Always commit changes to it.

3. **DON'T edit `hardware-configuration.nix`** - It's auto-generated and machine-specific (pins filesystem UUIDs and the LUKS device). Regenerate with `nixos-generate-config` if needed.

4. **DON'T bump `system.stateVersion`** - It records the release this machine was *first* installed with, not the current one.

5. **X11 won't autostart** - Run `startdm` manually to launch i3 window manager.

6. **DON'T use `-uall` with git status** - Can cause memory issues on large repos.

7. **Read files before editing** - Always check current state with Read tool before making changes.

8. **Test before committing** - `./recrank.sh` needs an interactive sudo password. To verify unattended, use `nix build .#nixosConfigurations.wiremind.config.system.build.toplevel --no-link`.

9. **All changes are declarative** - Don't suggest imperative package installs. Everything goes through `configuration.nix`.

10. **`~/.local/bin` is NOT on PATH in i3 keybindings** - Bindings in `sources/i3config.conf` need full paths (`~/.local/bin/screenz`). Nix-managed binaries are fine unqualified.

---

## Project Structure

```
dotfiles/
├── flake.nix                  # Flake definition (inputs & outputs)
├── flake.lock                 # Pinned dependency versions (COMMIT THIS)
├── configuration.nix          # Main NixOS config (EDIT THIS)
├── hardware-configuration.nix # Auto-generated, machine-specific (DON'T EDIT)
├── gpu.nix                    # NVIDIA/Intel hybrid — DISABLED (hardware defect)
├── recrank.sh                 # Rebuild script (flake-based)
├── upgrade.sh                 # Update script (updates flake.lock)
├── cleanup.sh / cleanup-hard.sh # Garbage collection
├── nix-work/                  # Optional work module stub (override input)
├── docs/CLAUDE_COMPREHENSIVE.md # Full system documentation
│
└── sources/                   # All dotfiles live here
    ├── vimrc                  # Vim config (fallback editor, 15 sections)
    ├── nvim/                  # Neovim config (primary editor)
    │   ├── init.lua           # Entry point
    │   └── lua/
    │       ├── config/        # Core settings
    │       │   ├── options.lua
    │       │   ├── keymaps.lua
    │       │   ├── autocmds.lua   # incl. Python \x pudb mapping
    │       │   └── lsp.lua        # Diagnostics + on-attach LSP keymaps
    │       └── plugins/       # Plugin specs & config (lazy.nvim)
    │           └── init.lua
    ├── bashrc.sh              # Bash interactive shell
    ├── bash_profile.sh        # Login shell init
    ├── bash_prompt.sh         # Prompt
    ├── path.sh                # PATH (~/.local/bin) + TMPDIR
    ├── aliases.sh             # Shell aliases
    ├── direnvrc.sh            # direnv functions
    ├── direnv.toml            # direnv config (auto-allow Workspace)
    ├── gitconfig.conf         # Git config
    ├── gpg-agent.conf         # GPG agent
    ├── i3config.conf          # i3 window manager
    ├── kitty.conf             # Terminal
    ├── rofi-config.rasi       # Application launcher
    ├── zellij.kdl             # Zellij config
    ├── zellij-layout.kdl      # Default layout
    ├── zellij-layout-dev.kdl  # Dev layout (nvim + two terminals)
    ├── yazi.toml              # File manager
    ├── yazi_keymap.toml       # File manager keymaps
    ├── tam-config.toml        # Terminal agent multiplexer
    ├── claude-settings.json   # Claude Code user settings
    ├── zen.nix                # Zen browser HM module (declarative extensions)
    ├── config.nix             # User nixpkgs config
    │
    └── scripts/               # Custom utilities → ~/.local/bin
        ├── screenz            # Monitor configuration
        ├── startdm            # Start display manager
        ├── switchkb           # Keyboard layout toggle
        ├── nixinit            # Project scaffolding (envrc + shell.nix + git excludes)
        ├── dcs                # Docker Compose services helper
        ├── k9                 # Pick a process with fzf and kill it
        ├── dev-open           # Open kitty + zellij session for a directory
        ├── tam-open           # Pick a project via rofi, launch dev session
        └── morning            # Startup housekeeping (systemd user service)
```

---

## System Details

- **User:** cbertrand
- **Hostname:** wiremind
- **NixOS:** 26.05 (+ unstable flake input for bleeding-edge)
- **Config Style:** Nix Flakes (reproducible builds via flake.lock)
- **Window Manager:** i3
- **Terminal:** kitty + zellij
- **Editor (primary):** Neovim with native LSP (pyright, ts_ls, lua_ls; Rust via rustaceanvim), Treesitter, lazy.nvim
- **Editor (fallback):** Vim with ALE (Python: ruff+pyright, Rust: rust-analyzer, TS: tsserver+eslint)
- **Shell:** Bash with direnv
- **Browser:** Zen (declarative extensions via `sources/zen.nix`)
- **File sync:** Syncthing (`documents`, `workspace` folders)
- **Timezone:** Europe/Paris
- **State version:** 23.05 — a first-install marker, do NOT bump it

---

## External Dependencies

**Optional (work-only):**
- `../nix-work` - Work-specific config (scripts auto-override `nix-work` input)

**Managed by flake.nix (no manual setup needed):**
- nixpkgs 26.05 (stable)
- nixpkgs-unstable (bleeding-edge packages)
- home-manager release-26.05

All dependencies are pinned in `flake.lock` for reproducibility.

---

## Neovim Quick Reference

**Leader key:** `\`

```lua
-- Navigation
\f              Telescope git files
\F              Telescope all files
;               Telescope buffers
\g              Telescope live grep
\n              Open yazi at current file
\s              Aerial code outline
Ctrl+H/J/K/L    Navigate splits (zellij-aware)
\z              Toggle zellij pane fullscreen
\w{h,v,e,l,r}   Window sizing (max height/width, equalize, shrink/grow)

-- Code Intelligence (Native LSP)
\b              Go to definition
\r              Find references
\R              Rename symbol
\a              Code actions
K               Hover documentation
gD / gi         Go to declaration / implementation
\D / \k         Type definition / signature help
]d / [d         Next/prev diagnostic
]e / [e         Next/prev error

-- Git (Gitsigns)
]h / [h         Next/prev hunk
\hs             Stage hunk
\hu             Undo hunk
\hp             Preview hunk
\hb             Blame line

-- Testing (neotest)
\tn             Run nearest test
\tf             Run test file
\ts             Run test suite
\tl             Run last test

-- Terminals
\th / \tv       Open terminal in horizontal / vertical split

-- Python specific
\x              Insert pudb breakpoint

-- Misc
\cp             Copy relative file path to clipboard
\<space>        Clear search highlighting

-- Plugin management
:Lazy           Open lazy.nvim UI (:Lazy restore / sync / clean)
```

LSP servers are installed from `configuration.nix`, **not** Mason — Mason is not
part of this config.

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
nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
home-manager.url = "github:nix-community/home-manager/release-26.05";
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
sudo nixos-rebuild switch --rollback --flake .#wiremind
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
- Check LSP server installed in configuration.nix (there is no Mason in this config)
- Verify the server is in the `vim.lsp.enable` loop in `sources/nvim/lua/plugins/init.lua`
- Run `:LspInfo` to see active LSP clients
- Run `:checkhealth` for diagnostics
- Check `:messages` for errors

**Syncthing not syncing:**
- `systemctl status syncthing.service syncthing-init.service`
- Confirm the peer's ID is in `syncthingPeers` — GUI-added devices are wiped on rebuild
- Check the folder is not excluded by `ignorePatterns` (workspace ignores build dirs)
- `journalctl -u syncthing -e`

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

**Last Updated:** 2026-08-03
