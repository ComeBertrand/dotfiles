# CLAUDE.md - AI Assistant Guide for NixOS Dotfiles Repository

**Last Updated:** 2026-01-23
**Repository Owner:** Come Bertrand
**NixOS Version:** 24.05
**System State Version:** 23.05

---

## Table of Contents

1. [Repository Overview](#repository-overview)
2. [Codebase Structure](#codebase-structure)
3. [Key Files Reference](#key-files-reference)
4. [Development Workflow](#development-workflow)
5. [NixOS-Specific Conventions](#nixos-specific-conventions)
6. [Vim Configuration](#vim-configuration)
7. [Git Conventions](#git-conventions)
8. [Maintenance Procedures](#maintenance-procedures)
9. [AI Assistant Guidelines](#ai-assistant-guidelines)

---

## Repository Overview

This is a **NixOS dotfiles repository** that manages system-wide and user-specific configuration for a development workstation. It uses:

- **NixOS** for declarative system configuration
- **Home Manager** (24.05) for user-level dotfile management
- **i3 window manager** as the desktop environment
- **Vim** as the primary text editor with extensive LSP/linting setup
- **Bash** as the default shell
- **Docker** for containerization
- **Kubernetes tooling** (kubectl, helm, k9s, telepresence)

### Primary Use Cases
- Python development (with pyright, ruff)
- Rust development (with rust-analyzer, rustfmt)
- TypeScript development (with tsserver, eslint)
- LaTeX document preparation
- Kubernetes cluster management
- AWS cloud infrastructure work

---

## Codebase Structure

```
/home/user/dotfiles/
├── configuration.nix              # Main NixOS system configuration
├── hardware-configuration.nix     # Hardware-specific settings (auto-generated)
├── README.md                      # Setup and startup manual
├── .gitignore                     # Git ignore rules (*.swp, *.swo)
│
├── sources/                       # User configuration files
│   ├── config.nix                 # Nixpkgs custom config
│   ├── vimrc                      # Comprehensive Vim configuration
│   ├── bashrc.sh                  # Bash interactive shell config
│   ├── bash_profile.sh            # Bash login shell config
│   ├── bash_prompt.sh             # Custom prompt configuration
│   ├── path.sh                    # PATH additions
│   ├── aliases.sh                 # Shell aliases (e.g., clippy alias)
│   ├── direnvrc.sh                # Direnv custom functions
│   ├── gitconfig.conf             # Git user config & aliases
│   ├── tmux.conf                  # Tmux configuration
│   ├── i3config.conf              # i3 window manager config
│   ├── xresources                 # X11 resources (colors, URxvt)
│   ├── gpg-agent.conf             # GPG agent configuration
│   ├── rxvt-resize-font           # URxvt font resizing plugin
│   │
│   └── scripts/                   # Custom utility scripts
│       ├── screenz                # Auto-configure monitors
│       ├── startdm                # Start display manager
│       ├── switchkb               # Toggle US/FR keyboard layouts
│       ├── setexclude             # Configure git info/exclude
│       └── k9                     # K9s wrapper
│
└── Shell scripts (root level)
    ├── recrank.sh                 # Main rebuild script
    ├── upgrade.sh                 # Package upgrade helper
    ├── cleanup.sh                 # System cleanup
    └── cleanup-hard.sh            # Aggressive cleanup
```

---

## Key Files Reference

### Core NixOS Configuration

#### `configuration.nix` (Lines: 323)
**Purpose:** Main system configuration entry point
**Key Sections:**
- **Lines 15-22:** Boot configuration (systemd-boot, EFI)
- **Lines 25:** Hostname set to "wiremind"
- **Lines 42-58:** Locale (Europe/Paris timezone, FR locale settings)
- **Lines 61-97:** Display server (X11 + i3 window manager, manual start)
- **Lines 128-129:** Docker virtualization enabled
- **Lines 132-174:** User account "cbertrand" with package list
- **Lines 176-237:** Home Manager integration (dotfile linking)
- **Lines 240-247:** Unfree and insecure package permissions
- **Lines 249-268:** System-wide packages (Python 3.12, uv, vim, Claude Code, etc.)
- **Lines 280-293:** nix-ld for pre-built executables (important for ruff, etc.)

**Important Notes:**
- Uses `<home-manager/nixos>` module (must be in NIX_PATH)
- Imports `../nix-work` (external work-specific config, not in repo)
- X11 autorun disabled (line 77) - requires manual `startdm`
- Contains unstable channel usage for claude-code, gemini-cli, codex

#### `hardware-configuration.nix`
**Purpose:** Auto-generated hardware detection
**Convention:** DO NOT manually edit unless necessary; regenerate with `nixos-generate-config`

#### `sources/config.nix`
**Purpose:** User-level nixpkgs configuration
**Current State:** Permits insecure nodejs-14.21.3 and openssl-1.1.1u for legacy projects

---

### Vim Configuration

#### `sources/vimrc` (Lines: 689)
**Purpose:** Comprehensive Vim setup for polyglot development
**Architecture:** Well-organized into 15 sections with inline documentation

**Key Features:**
- **Plugin Manager:** vim-plug (auto-installs if missing)
- **LSP/Linting:** ALE with language-specific linters
  - Python: ruff + pyright
  - Rust: rust-analyzer
  - TypeScript: tsserver + eslint
- **Completion:** ALE-powered LSP completion
- **Git:** vim-fugitive + vim-gitgutter
- **Navigation:** FZF (fuzzy finder), Ranger, Tagbar
- **AI:** GitHub Copilot integration
- **Testing:** vim-test + vim-dispatch
- **Colorscheme:** Gruvbox dark

**Critical Keybindings (Leader = `\`):**
- `\b` - Go to definition (ALE)
- `\r` - Find references (ALE)
- `\R` - Rename symbol (ALE)
- `\f` - FZF file search
- `\n` - Ranger file explorer
- `\tn/tf/ts/tl` - Test nearest/file/suite/last
- `Ctrl+H/J/K/L` - Navigate splits (tmux-aware)

**Configuration Philosophy:**
- Auto-fix on save enabled (`g:ale_fix_on_save = 1`)
- Persistent undo enabled (`~/.vim/tmp.undo/`)
- Hybrid line numbers (absolute + relative)
- System clipboard integration

---

### Shell Configuration

#### `sources/bashrc.sh`
**Purpose:** Interactive bash shell initialization
**Key Features:**
- Loads `~/.bash_profile` (line 77-79)
- Direnv hook enabled (line 93)
- Auto-starts ssh-agent (lines 95-96)
- Custom ls aliases with colors and grouping

#### `sources/bash_profile.sh`
**Purpose:** Login shell initialization (sources PATH, aliases, prompt)

#### `sources/aliases.sh`
**Purpose:** Shell command aliases
**Current Aliases:**
- `clippy` - Cargo clippy with strict settings (`-D warnings -A clippy::new_without_default`)

#### `sources/gitconfig.conf`
**Purpose:** Git user configuration
**Key Settings:**
- User: Come Bertrand <come.bertrand@protonmail.com>
- Color UI: auto
- Alias: `git tree` - Pretty log graph

---

### Utility Scripts

#### `recrank.sh`
**Purpose:** Main rebuild script for NixOS configuration
**Command:** `sudo nixos-rebuild switch -I nixos-config=configuration.nix --verbose`
**Usage:** Run from repository root after making configuration changes

#### `sources/scripts/screenz`
**Purpose:** Automatically configure monitor layout
**Usage:** Run `screenz` when monitors change

#### `sources/scripts/switchkb`
**Purpose:** Toggle between US and FR keyboard layouts
**Usage:** Bind to hotkey in i3config for quick switching

#### `sources/scripts/startdm`
**Purpose:** Manually start X11 display manager
**Context:** Required because `services.xserver.autorun = false` in configuration.nix

#### `sources/scripts/setexclude`
**Purpose:** Configure `.git/info/exclude` for custom local ignores
**Usage:** Run in new git repositories to set up project-specific ignores

---

## Development Workflow

### Making Configuration Changes

1. **Edit Configuration Files**
   - Modify `configuration.nix` or files in `sources/`
   - Follow Nix syntax conventions (functions, attribute sets)

2. **Test Changes**
   ```bash
   # Dry-run (optional, not very helpful per README line 61)
   sudo bash -x $(nix-build --no-out-link '<nixos/nixos>' -A system -I nixos-config=configuration.nix)/activate

   # Apply changes
   ./recrank.sh
   # OR manually:
   sudo nixos-rebuild switch -I nixos-config=configuration.nix --verbose
   ```

3. **Verify**
   - Check that services are running
   - Test new package installations
   - Verify dotfile symlinks in home directory

4. **Commit Changes**
   - Use descriptive commit messages (see [Git Conventions](#git-conventions))
   - Follow existing patterns: `feat:`, `fix:`, `chore:`

### Adding New Packages

**User Packages** (installed for user cbertrand only):
- Edit `configuration.nix` line 136-173 under `users.users.cbertrand.packages`
- Add package from nixpkgs, e.g., `my-package`

**System Packages** (available to all users):
- Edit `configuration.nix` line 249-268 under `environment.systemPackages`
- For unstable packages, use pattern: `unstable.package-name`

**Unfree Packages:**
- Already allowed globally (line 240: `nixpkgs.config.allowUnfree = true`)

**Insecure Packages:**
- Add to `nixpkgs.config.permittedInsecurePackages` (lines 244-247)
- Also update `sources/config.nix` for user-level commands

### Adding New Dotfiles

1. **Create source file** in `sources/` directory
2. **Link via Home Manager** in `configuration.nix` under `home-manager.users.cbertrand.home.file`
3. **Example pattern:**
   ```nix
   ".config/myapp/config.toml" = {
     source = ./sources/myapp.toml;
   };
   ```
4. **Run `./recrank.sh`** to activate

---

## NixOS-Specific Conventions

### Channel Management

**Current Channels:**
- Main: nixos-24.05
- Unstable: nixos-unstable (for bleeding-edge packages)

**Important:** ALWAYS use `sudo` with `nix-channel` commands:
```bash
# CORRECT
sudo nix-channel --add <url> <name>
sudo nix-channel --update

# INCORRECT (will silently fail)
nix-channel --add <url> <name>
```

### Upgrading NixOS Version

Follow guide: https://nixos.org/manual/nixos/stable/index.html#sec-upgrading

1. Update channels to new version
2. Run `sudo nix-channel --update`
3. Run `./upgrade.sh` or `sudo nixos-rebuild switch --upgrade`
4. Reboot system

### Package Upgrades

See: https://superuser.com/questions/1604694/how-to-update-every-package-on-nixos

```bash
# Update all packages
./upgrade.sh

# Manual approach
sudo nixos-rebuild switch --upgrade --verbose
```

### Nix Language Patterns

**Attribute Sets:**
```nix
{ key = value; key2 = value2; }
```

**List Concatenation:**
```nix
[ item1 item2 ] ++ [ item3 ]
```

**Let-In Expressions:**
```nix
let
  unstable = import <nixos-unstable> { config = { allowUnfree = true; }; };
in
[ unstable.package ]
```

**Function Imports:**
```nix
{ config, pkgs, ... }:  # Function that receives config and pkgs
```

---

## Vim Configuration

### Plugin Management

**Install/Update Plugins:**
```vim
:PlugInstall    " Install missing plugins
:PlugUpdate     " Update all plugins
:PlugClean      " Remove unused plugins
:PlugStatus     " Check plugin status
```

### Language Server Setup

**Python:**
- Linters: ruff, pyright (auto-configured via ALE)
- Formatters: ruff, ruff_format
- Auto-fix on save: enabled
- Debugger: pudb (insert with `\x`)

**Rust:**
- Linter: rust-analyzer
- Formatter: rustfmt (auto-save enabled via `g:rustfmt_autosave`)
- Workspace-wide checks enabled

**TypeScript:**
- Linters: tsserver, eslint
- Formatters: prettier, eslint

### Adding New Language Support

1. **Add vim plugin** to `sources/vimrc` in plug#begin() section
2. **Configure ALE linters** in `g:ale_linters` dictionary
3. **Configure ALE fixers** in `g:ale_fixers` dictionary
4. **Add language-specific settings** in Section 13 (Language-Specific Settings)
5. **Ensure system packages installed** in `configuration.nix`

---

## Git Conventions

### Commit Message Format

**Pattern:** `<type>: <description>`

**Types:**
- `feat:` - New features or functionality
- `fix:` - Bug fixes
- `chore:` - Maintenance tasks (updates, cleanup)
- `docs:` - Documentation changes
- `refactor:` - Code restructuring without behavior change

**Examples from history:**
```
feat: add vim-test to vimrc
chore: Add comment and documentation to vimrc
feat: better ale search symbol
feat: use uv as a python package manager
chore: remove aider stuff
```

### Branching Strategy

- Main branch: `master` or `main`
- Feature branches: Use descriptive names
- PR workflow: Enabled (see PR #1 in history)

### Git Workflow Tools

**Built-in Aliases:**
- `git tree` - Visual commit graph with colors and dates

**Vim Integration:**
- vim-fugitive: Full Git client inside Vim (`:Git`, `:Gblame`, etc.)
- vim-gitgutter: Shows diff markers in sign column
- Keybindings: `]h`/`[h` (navigate hunks), `\hs` (stage), `\hu` (undo), `\hp` (preview)

---

## Maintenance Procedures

### System Cleanup

```bash
# Standard cleanup
./cleanup.sh

# Aggressive cleanup (use with caution)
./cleanup-hard.sh
```

### SSH Key Setup

After fresh install or key rotation:

```bash
mkdir ~/.ssh
cd ~/.ssh
ssh-keygen -a 100 -t ed25519 -C "myemail@email.com"
chmod -R 700 ~/.ssh
```

Then add public key to GitHub, GitLab, etc.

### Home Manager Installation

**First-time setup** (if not already installed):
```bash
sudo nix-channel --add https://github.com/nix-community/home-manager/archive/release-24.05.tar.gz home-manager
sudo nix-channel --update
```

### Firefox Extensions

**Recommended extensions** (manual installation):
- Bitwarden (password manager)
- Ghostery (privacy)
- uBlock Origin (ad blocker)

### Monitoring & Debugging

**Tools available:**
- `htop` - Process monitoring
- `k9s` - Kubernetes cluster visualization
- `visidata` - Data analysis in terminal
- `nix-tree` - Explore package dependency trees
- `kcachegrind` + `graphviz` - Profile visualization

---

## AI Assistant Guidelines

### When Modifying Configuration

1. **ALWAYS read files before editing**
   - Use Read tool on configuration.nix, vimrc, or other files
   - Understand current state before making changes

2. **Preserve NixOS declarative patterns**
   - Don't suggest imperative commands for package installation
   - All changes should go through configuration.nix
   - Use proper Nix syntax

3. **Test before committing**
   - Suggest running `./recrank.sh` to test changes
   - Warn about potential breaking changes
   - Check for syntax errors in Nix expressions

4. **Follow existing conventions**
   - Match indentation (2 spaces in .nix files, 4 spaces in .vim)
   - Use same commenting style
   - Follow commit message patterns

5. **Be cautious with system-critical files**
   - hardware-configuration.nix - Don't modify unless necessary
   - Boot loader settings - Double-check before changing
   - User accounts - Verify group memberships

### Understanding User Context

**System Details:**
- **Hostname:** wiremind
- **User:** cbertrand
- **Timezone:** Europe/Paris (CET/CEST)
- **Locale:** en_US.UTF-8 with FR regional settings
- **Window Manager:** i3 (manual start with `startdm`)
- **Terminal:** URxvt (rxvt-unicode)
- **Editor:** Vim (configured for Python/Rust/TS development)

**Common Tasks:**
- Python development (likely professional, uses pyright + ruff)
- Kubernetes operations (kubectl, helm, k9s, telepresence)
- AWS operations (awscli2)
- Rust development (with clippy configured strictly)
- Document preparation (LaTeX with scheme-full)

### Code Style Preferences

**Vim Configuration:**
- Heavy inline documentation (see vimrc sections)
- Organized into logical sections with headers
- Descriptive comments for keybindings
- Quick reference cards at end of file

**Nix Configuration:**
- Inline comments for non-obvious settings
- Grouped by functional area
- Explicit over implicit

**Shell Scripts:**
- Simple and direct
- Minimal error handling (fail fast)
- Verbose flags preferred (`--verbose`)

### Security Considerations

1. **Permitted insecure packages** are intentional (nodejs-14 for legacy projects)
2. **Docker access** granted to user (in docker group)
3. **SSH agent** auto-starts in bashrc
4. **GPG agent** configured for signing
5. **Secrets management** via infisical CLI

### External Dependencies

**Not in Repository:**
- `../nix-work` - Work-specific configuration (imported in configuration.nix line 12)
- Home Manager channel (must be added manually)
- Unstable channel (for bleeding-edge packages)

**When suggesting changes involving these:**
- Mention the dependency clearly
- Provide setup instructions if missing
- Don't assume they exist

### Performance Considerations

- **nix-ld enabled** (lines 280-293) - Allows pre-built executables
- **ALE async** - Linting doesn't block editing
- **Persistent undo** - Undo files stored, can grow large
- **Git with submodules** - Be aware of .gitignore (only vim swap files)

### Common Pitfalls to Avoid

1. **DON'T forget `sudo` with nix-channel** - It won't work otherwise
2. **DON'T use -uall flag with git status** - Can cause memory issues (per vimrc line 333)
3. **DON'T modify hardware-configuration.nix** - Auto-generated file
4. **DON'T use `--no-edit` with git rebase** - Not a valid option
5. **DON'T use interactive flags** (`-i`) with git commands in automation

### Helpful Patterns

**Adding a Vim Plugin:**
```vim
" In sources/vimrc, Section 9
Plug 'author/plugin-name'  " Description

" Then configure in Section 11
let g:plugin_setting = value
```

**Adding a System Package:**
```nix
# In configuration.nix, environment.systemPackages
environment.systemPackages = with pkgs; [
  existing-package
  new-package  # Brief description
];
```

**Adding a User Package:**
```nix
# In configuration.nix, users.users.cbertrand.packages
packages = with pkgs; [
  existing-package
  new-package  # Brief description
];
```

### Response Format Preferences

- **Be concise but complete**
- **Show exact file locations** with line numbers when referencing code
- **Provide commands ready to run** (no placeholders like `<path>` if actual path is known)
- **Explain NixOS-specific concepts** (declarative, channels, generations)
- **Test instructions** before suggesting complex changes

---

## Quick Reference

### Essential Commands

| Command | Purpose |
|---------|---------|
| `./recrank.sh` | Rebuild and switch NixOS config |
| `./upgrade.sh` | Upgrade all packages |
| `sudo nixos-rebuild switch` | Apply config (manual) |
| `sudo nix-channel --update` | Update channels |
| `screenz` | Configure monitors |
| `startdm` | Start X11/i3 |
| `switchkb` | Toggle US/FR keyboard |
| `setexclude` | Setup git local excludes |

### Key File Locations

| File | Purpose |
|------|---------|
| `/home/user/dotfiles/configuration.nix` | Main system config |
| `/home/user/dotfiles/sources/vimrc` | Vim configuration |
| `/home/user/dotfiles/sources/bashrc.sh` | Bash interactive config |
| `/home/user/dotfiles/sources/i3config.conf` | i3 window manager |
| `~/.config/git/config` | Git user config (symlink) |
| `~/.vimrc` | Vim config (symlink) |
| `~/.local/bin/*` | Custom scripts (symlinked) |

### Important URLs

- NixOS Manual: https://nixos.org/manual/nixos/stable/
- Home Manager: https://github.com/nix-community/home-manager
- Package Upgrades: https://superuser.com/questions/1604694/how-to-update-every-package-on-nixos
- NixOS Version Upgrade: https://nixos.org/manual/nixos/stable/index.html#sec-upgrading

---

## Version History

- **2026-01-23:** Initial CLAUDE.md creation
- Document reflects state at commit `a6d59ae` (feat: add vim-test to vimrc)

---

## Notes for Future Updates

When updating this document:
1. Update "Last Updated" date at top
2. Verify NixOS version and state version
3. Check that package lists are current
4. Verify external URLs are still valid
5. Update commit references in Version History
6. Test all command examples in a safe environment

---

**End of CLAUDE.md**
