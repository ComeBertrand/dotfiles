# CLAUDE.md

**NixOS declarative configuration for Python/Rust/TypeScript development with i3, Vim, and Kubernetes tooling.**

---

## Essential Commands

```bash
./recrank.sh                        # Apply configuration changes
./upgrade.sh                        # Update all packages
sudo nix-channel --update           # Update channels (MUST use sudo!)
sudo nixos-rebuild switch           # Manual config rebuild

# Utility scripts
screenz                             # Configure monitors
startdm                             # Start X11/i3 (required - autorun disabled)
switchkb                            # Toggle US/FR keyboard
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

# Unstable package
environment.systemPackages = with pkgs; [
  unstable.bleeding-edge-package
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

### Configure ALE for New Language

```vim
" In sources/vimrc - ALE configuration
let g:ale_linters = {
\   'mylang': ['linter-name'],
\}

let g:ale_fixers = {
\   'mylang': ['formatter-name'],
\}
```

Install linter/formatter in `configuration.nix` packages.

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

1. **ALWAYS use `sudo`** with `nix-channel` commands - user-level commands silently fail
   ```bash
   # ✅ CORRECT
   sudo nix-channel --add <url> <name>

   # ❌ WRONG - will fail silently
   nix-channel --add <url> <name>
   ```

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
├── configuration.nix          # Main NixOS config (EDIT THIS)
├── hardware-configuration.nix # Auto-generated (DON'T EDIT)
├── recrank.sh                 # Rebuild script
├── upgrade.sh                 # Update script
│
└── sources/                   # All dotfiles live here
    ├── vimrc                  # Comprehensive Vim config
    ├── bashrc.sh              # Bash interactive shell
    ├── bash_profile.sh        # Login shell init
    ├── aliases.sh             # Shell aliases
    ├── gitconfig.conf         # Git config
    ├── i3config.conf          # i3 window manager
    ├── tmux.conf              # Tmux config
    ├── config.nix             # User nixpkgs config
    │
    └── scripts/               # Custom utilities
        ├── screenz            # Monitor configuration
        ├── startdm            # Start display manager
        ├── switchkb           # Keyboard layout toggle
        └── setexclude         # Git exclude setup
```

---

## System Details

- **User:** cbertrand
- **Hostname:** wiremind
- **NixOS:** 24.05 (+ unstable channel for bleeding-edge)
- **Window Manager:** i3
- **Editor:** Vim with ALE (Python: ruff+pyright, Rust: rust-analyzer, TS: tsserver+eslint)
- **Shell:** Bash with direnv
- **Timezone:** Europe/Paris

---

## External Dependencies

**Not in repo - must exist:**
- `../nix-work` - Work-specific config (imported by configuration.nix)
- Home Manager channel (release-24.05)
- Unstable channel (nixos-unstable)

**Setup if missing:**
```bash
sudo nix-channel --add https://github.com/nix-community/home-manager/archive/release-24.05.tar.gz home-manager
sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos-unstable
sudo nix-channel --update
```

---

## Vim Quick Reference

**Leader key:** `\`

```vim
" Navigation
\f              FZF file search (git files)
;               FZF buffer search
\n              Ranger file explorer
\s              Tagbar (code structure)
Ctrl+H/J/K/L    Navigate splits (tmux-aware)

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
```bash
# Update channel URLs to new version
sudo nix-channel --list
sudo nix-channel --add https://nixos.org/channels/nixos-25.05 nixos
sudo nix-channel --update
./upgrade.sh
sudo reboot
```

---

## When Things Break

**Syntax error in configuration.nix:**
```bash
nix-instantiate --parse configuration.nix
# Shows where syntax error is
```

**Rollback to previous generation:**
```bash
nixos-rebuild --rollback
# OR use boot menu to select previous generation
```

**Vim plugins broken:**
```vim
:PlugClean      " Remove unused
:PlugInstall    " Reinstall
:PlugUpdate     " Update all
```

**ALE not working:**
- Check linter/formatter installed in configuration.nix
- Run `:ALEInfo` in Vim to see diagnostics
- Verify `g:ale_linters` and `g:ale_fixers` dictionaries

---

## Additional Documentation

For comprehensive details, see:
- **[docs/CLAUDE_COMPREHENSIVE.md](docs/CLAUDE_COMPREHENSIVE.md)** - Full system documentation
- **[README.md](README.md)** - Setup and startup manual

---

**Last Updated:** 2026-01-23
