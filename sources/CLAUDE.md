# CLAUDE.md - Sources Directory

**Configuration files and scripts for shell, Vim, and system utilities.**

---

## Vim Configuration (vimrc)

### Architecture

Organized into 15 sections:
1. Core Settings
2. Display and Visual
3. Search Settings
4. Indentation and Tabs
5. Persistent Undo
6. Window and Split Management
7. Buffer Handling
8. Wildmenu
9. **Plugin Manager** (vim-plug with auto-install)
10. Colorscheme
11. **Plugin Configurations** (ALE, GitGutter, FZF, etc.)
12. **Key Mappings** (all keybindings in one place)
13. **Language-Specific Settings** (Python, Rust, TS)
14. Custom Commands
15. Extra Configuration

### Adding Features

**New plugin:**
```vim
" Section 9: Plugin Manager
call plug#begin()
Plug 'author/new-plugin'  " Description
call plug#end()

" Section 11: Plugin Configurations
let g:new_plugin_setting = value
```

**New keybinding:**
```vim
" Section 12: Key Mappings
nnoremap <leader>x :MyCommand<CR>
```

**Language support:**
```vim
" Section 11: ALE Configuration
let g:ale_linters = {
\   'python': ['ruff', 'pyright'],
\   'newlang': ['new-linter'],
\}

" Section 13: Language-Specific Settings
augroup ft_newlang
    au!
    au FileType newlang setlocal tabstop=2 shiftwidth=2
augroup END
```

---

## Shell Configuration

### File Loading Order

1. **bash_profile.sh** - Login shell init
   - Sources `path.sh` (PATH additions)
   - Sources `aliases.sh` (command shortcuts)
   - Sources `bash_prompt.sh` (custom prompt)

2. **bashrc.sh** - Interactive shell init
   - Loads bash_profile
   - Enables direnv hook
   - Auto-starts ssh-agent

### Adding Aliases

```bash
# In aliases.sh
alias mycommand='actual-command --with-flags'

# Example: strict rust linting
alias clippy='cargo clippy -- -D warnings -A clippy::new_without_default'
```

### Adding PATH Entries

```bash
# In path.sh
export PATH="$HOME/.local/bin:$PATH"
export PATH="/custom/directory:$PATH"
```

---

## Git Configuration (gitconfig.conf)

```ini
[user]
    name = Your Name
    email = your.email@example.com

[alias]
    # Visual commit graph
    tree = log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative

    # Add your own aliases here
    st = status
    co = checkout
```

---

## Custom Scripts

### screenz
**Purpose:** Auto-configure monitor layout using xrandr
**Usage:** Run when monitors change
**Location:** Sources from `~/.local/bin/screenz`

### startdm
**Purpose:** Start X11 display manager and i3
**Why needed:** `services.xserver.autorun = false` in system config
**Usage:** Run after login to start graphical environment

### switchkb
**Purpose:** Toggle between US and FR keyboard layouts
**Implementation:** Uses `setxkbmap` to switch layouts
**Typical use:** Bound to i3 hotkey for quick access

### nixinit
**Purpose:** Scaffold `.envrc` and `shell.nix` for a project, configure git excludes
**Usage:** `nixinit python`, `nixinit python rust`, `nixinit python --source ~/wmdotfiles/projects`
**Languages:** python, rust, node
**Behavior:** Generates nix dev shell with language-specific packages, creates `.envrc`, configures git excludes (idempotent). Skips existing files.

### k9
**Purpose:** Wrapper for k9s (Kubernetes TUI)
**Usage:** `k9` instead of `k9s`

---

## Config.nix (User Nixpkgs)

**Purpose:** User-level package configuration

```nix
{
  # Allow unfree packages for user commands
  allowUnfree = true;

  # Allow specific insecure packages
  permittedInsecurePackages = [
    "nodejs-14.21.3"
    "openssl-1.1.1u"
  ];
}
```

**When to edit:** When system config has `permittedInsecurePackages`, mirror them here for user-level nix commands.

---

## Best Practices

### Vim
- Keep sections organized (don't mix plugin installs with config)
- Document keybindings inline with comments
- Use `augroup` for filetype-specific settings
- Test plugins before adding to permanent config

### Shell
- Keep aliases simple and memorable
- Use full paths in scripts for reliability
- Source order matters (path → aliases → prompt)
- Test in new shell: `bash --login` or `bash -i`

### Scripts
- Use `#!/usr/bin/env bash` for portability
- Fail fast (don't add extensive error handling)
- Verbose output preferred (`--verbose` flags)
- Make executable: `chmod +x sources/scripts/myscript`

---

**For system-level changes, see [../CLAUDE.md](../CLAUDE.md)**
