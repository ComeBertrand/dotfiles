# CLAUDE.md - AI Assistant Guide for NixOS Dotfiles Repository

**Last Updated:** 2026-02-04
**Repository Owner:** Come Bertrand
**NixOS Version:** 25.05
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
- **Home Manager** (25.05) for user-level dotfile management
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

#### `configuration.nix`
**Purpose:** Main system configuration entry point

**Key Areas:**
- Boot configuration (systemd-boot, EFI)
- System hostname and networking
- Locale and timezone settings
- Display server configuration (X11 + i3 window manager)
- Virtualization (Docker)
- User account management and package installation
- Home Manager integration for dotfile management
- Package permissions (unfree and insecure packages)
- System-wide packages and tools
- nix-ld for running pre-built executables

**Important Notes:**
- Home Manager module wired via flake (no NIX_PATH channel required)
- Work module is an optional flake input (defaults to repo stub; override to `../nix-work`)
- X11 autorun disabled - requires manual `startdm` to start display manager
- Uses `pkgs-unstable` from flake input for bleeding-edge packages

#### `hardware-configuration.nix`
**Purpose:** Auto-generated hardware detection
**Convention:** DO NOT manually edit unless necessary; regenerate with `nixos-generate-config`

#### `sources/config.nix`
**Purpose:** User-level nixpkgs configuration
**Usage:** Allows specific package overrides and permissions for user-level nix commands

---

### Vim Configuration

#### `sources/vimrc`
**Purpose:** Comprehensive Vim setup for polyglot development
**Architecture:** Well-organized into sections with extensive inline documentation

**Key Features:**
- **Plugin Manager:** vim-plug (auto-installs if missing)
- **LSP/Linting:** ALE with async linting and language servers for Python, Rust, TypeScript
- **Completion:** LSP-powered code completion
- **Git Integration:** Full Git workflow support with fugitive and gitgutter
- **Navigation:** Fuzzy finding (FZF), file explorer (Ranger), code structure (Tagbar)
- **AI Assistance:** GitHub Copilot integration
- **Testing:** Integrated test runner support
- **Visual:** Gruvbox dark theme with customized UI

**Configuration Philosophy:**
- Auto-fix on save for supported languages
- Persistent undo across sessions
- Hybrid line numbers for efficient navigation
- System clipboard integration
- Extensive keybindings documented in file (Leader = `\`)

---

### Shell Configuration

#### `sources/bashrc.sh`
**Purpose:** Interactive bash shell initialization
**Key Features:**
- Loads bash profile for login shell compatibility
- Direnv integration for per-directory environments
- SSH agent auto-start
- Custom aliases with enhanced ls output

#### `sources/bash_profile.sh`
**Purpose:** Login shell initialization (sources PATH, aliases, prompt configuration)

#### `sources/aliases.sh`
**Purpose:** Custom shell command aliases and shortcuts

#### `sources/gitconfig.conf`
**Purpose:** Git user configuration and custom aliases

---

### Utility Scripts

#### `recrank.sh`
**Purpose:** Main rebuild script for applying NixOS configuration changes
**Usage:** Run from repository root after editing configuration files

#### `sources/scripts/screenz`
**Purpose:** Automatically configure monitor layout
**Usage:** Run when monitors are connected/disconnected

#### `sources/scripts/switchkb`
**Purpose:** Toggle between US and FR keyboard layouts
**Usage:** Typically bound to i3 hotkey for quick switching

#### `sources/scripts/startdm`
**Purpose:** Manually start X11 display manager
**Context:** Required because X11 autorun is disabled

#### `sources/scripts/setexclude`
**Purpose:** Configure git local excludes
**Usage:** Run in new repositories to set up project-specific ignore patterns

---

## Development Workflow

### Making Configuration Changes

1. **Edit Configuration Files**
   - Modify `configuration.nix` or files in `sources/`
   - Follow Nix syntax conventions (functions, attribute sets)

2. **Test Changes**
   ```bash
   # Dry-run (optional, see README for details)
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
- Edit `configuration.nix` under `users.users.cbertrand.packages`
- Add package from nixpkgs

**System Packages** (available to all users):
- Edit `configuration.nix` under `environment.systemPackages`
- For unstable packages, use pattern: `unstable.package-name`

**Unfree Packages:**
- Already allowed globally via `nixpkgs.config.allowUnfree`

**Insecure Packages:**
- Add to `nixpkgs.config.permittedInsecurePackages` in `configuration.nix`
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
- Main: nixos-25.05
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

1. **Add vim plugin** to `sources/vimrc` in the plug#begin() section
2. **Configure ALE linters** in the `g:ale_linters` dictionary
3. **Configure ALE fixers** in the `g:ale_fixers` dictionary
4. **Add language-specific settings** in the language-specific settings section
5. **Ensure required LSP/linter packages** are installed in `configuration.nix`

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
sudo nix-channel --add https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz home-manager
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

**Optional (work-only):**
- `../nix-work` - Work-specific module (override `nix-work` input; repo ships stub)

**Managed by flake inputs (no manual channels needed):**
- nixpkgs 25.05 (stable)
- nixpkgs-unstable (bleeding-edge packages)
- home-manager release-25.05

**When suggesting changes involving these:**
- Mention the dependency clearly
- Provide setup instructions if missing
- Don't assume they exist

### Performance Considerations

- **nix-ld enabled** - Allows running pre-built executables
- **ALE async linting** - Non-blocking, maintains editing responsiveness
- **Persistent undo** - Undo files stored indefinitely, can accumulate over time
- **Git configuration** - Optimized for performance, be aware of .gitignore patterns

### Common Pitfalls to Avoid

1. **DON'T forget `sudo` with nix-channel** - User-level channel commands won't work
2. **DON'T use -uall flag with git status** - Can cause memory issues on large repos
3. **DON'T modify hardware-configuration.nix** - Auto-generated, regenerate if needed
4. **DON'T use `--no-edit` with git rebase** - Not a valid option for git rebase
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
- **Reference files clearly** - Mention specific configuration sections or settings by name
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

---

## Notes for Future Updates

When updating this document:
1. Update "Last Updated" date at top
2. Verify NixOS version and state version
3. Verify external URLs are still valid
4. Test all command examples in a safe environment
5. Keep descriptions focused on purpose rather than specific implementation details

---

**End of CLAUDE.md**
