# CLAUDE.md - Sources Directory

**Configuration files and scripts for shell, editors, and system utilities.**

Everything here is symlinked into `$HOME` by Home Manager, declared under
`home-manager.users.cbertrand.home.file` in `../configuration.nix`. Adding a file here
does nothing until it is both **declared there** and **`git add`ed** (flakes only see
git-tracked files).

---

## Neovim Configuration (nvim/) — primary editor

```
nvim/
├── init.lua                  # Entry point, bootstraps lazy.nvim
└── lua/
    ├── config/
    │   ├── options.lua       # Core settings
    │   ├── keymaps.lua       # Global keymaps (windows, terminals, \z, \cp)
    │   ├── autocmds.lua      # Autocommands, incl. Python \x pudb mapping
    │   └── lsp.lua           # Diagnostics config + on-attach LSP keymaps
    └── plugins/
        └── init.lua          # lazy.nvim plugin specs and their configuration
```

**Adding a plugin** — append to the table returned by `plugins/init.lua`:

```lua
{
  "author/plugin-name",
  config = function()
    require("plugin-name").setup({})
  end,
},
```

lazy.nvim installs it on next launch. `:Lazy` for the UI.

**Adding an LSP server** — native `vim.lsp` API (Neovim 0.11+), not `lspconfig.setup()`:

```lua
vim.lsp.config("mylang_ls", { settings = { ... } })

-- then add to the enable loop:
for _, server in ipairs({ "pyright", "ts_ls", "lua_ls", "mylang_ls" }) do
  vim.lsp.enable(server)
end
```

Currently enabled: **pyright**, **ts_ls**, **lua_ls**. Rust is handled by
**rustaceanvim**, which manages rust-analyzer itself — do not also declare it.

**Formatting/linting** — conform.nvim `formatters_by_ft` and nvim-lint `linters_by_ft`,
both in `plugins/init.lua`. The binaries must be installed in `../configuration.nix`;
there is no Mason in this config.

---

## Vim Configuration (vimrc) — fallback editor

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

Symlinked to `~/.config/git/config`. The one alias currently defined:

```ini
[alias]
    # Visual commit graph
    tree = log --pretty='%Cgreen%h%Creset [%ai] %s %Cred<%Creset%an%Cred>' --decorate --graph
```

Add further aliases in the same block.

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
**Purpose:** Interactive process killer — **not** a k9s wrapper despite the name
**Implementation:** `ps -aux | fzf` to pick a process, then kills the selected PID
**Usage:** `k9`

### dcs
**Purpose:** Docker Compose services helper
**Usage:** Run from anywhere inside a project containing a `compose.yaml`

### dev-open
**Purpose:** Open a kitty + zellij session for a project directory
**Usage:** `dev-open <dir> <name>`
**Note:** Used as yawn's `opener`, which splits on spaces rather than running a shell —
hence a wrapper script instead of an inline command

### tam-open
**Purpose:** Pick a project with tam + rofi, then launch a dev session

### morning
**Purpose:** Startup housekeeping — purges dead zellij sessions
**Usage:** Runs automatically as a systemd user service at login (`Type = oneshot`,
declared in `../configuration.nix`), not invoked by hand

---

## Config.nix (User Nixpkgs)

**Purpose:** User-level package configuration, symlinked to `~/.config/nixpkgs/config.nix`.
Current contents:

```nix
{
  permittedInsecurePackages = [
    "nodejs-14.21.3"  # Still required in old projects
    "openssl-1.1.1u"  # Needed for nodejs 14
  ];
}
```

**When to edit:** When the system config gains a `permittedInsecurePackages` entry, mirror
it here so user-level `nix` commands behave the same. Note `allowUnfree` is set
system-wide in `../configuration.nix`, not here.

---

## Other Configuration Files

| File | Symlinked to | Purpose |
|---|---|---|
| `kitty.conf` | `~/.config/kitty/kitty.conf` | Terminal emulator |
| `zellij.kdl` | `~/.config/zellij/config.kdl` | Multiplexer |
| `zellij-layout.kdl` | `~/.config/zellij/layouts/default.kdl` | Default layout (compact bar) |
| `zellij-layout-dev.kdl` | `~/.config/zellij/layouts/dev.kdl` | Dev layout (nvim + two terminals) |
| `yazi.toml`, `yazi_keymap.toml` | `~/.config/yazi/` | Terminal file manager |
| `rofi-config.rasi` | `~/.config/rofi/config.rasi` | Application launcher |
| `i3config.conf` | `~/.config/i3/config` | Window manager |
| `direnv.toml` | `~/.config/direnv/direnv.toml` | Auto-allow Workspace directories |
| `gpg-agent.conf` | `~/.gnupg/gpg-agent.conf` | GPG agent |
| `tam-config.toml` | `~/.config/tam/config.toml` | Terminal agent multiplexer |
| `claude-settings.json` | `~/.claude/settings.json` | Claude Code user settings |
| `zen.nix` | *(HM module, imported)* | Zen browser + declarative extensions |

`zen.nix` is imported as a Home Manager module rather than symlinked. Extensions come
from the `firefox-addons` NUR input (uBlock Origin, Bitwarden, ClearURLs); Proton Pass
and Proton VPN are force-installed via `policies.ExtensionSettings` because they are not
in that NUR.

A zellij autolock plugin (`.wasm`) is fetched by `pkgs.fetchurl` in `../configuration.nix`
rather than stored in this directory.

---

## Best Practices

### Neovim
- Keep `config/` (settings) and `plugins/` (specs) separate
- Give keymaps a `desc` — which-key surfaces it
- Filetype-specific mappings belong in `autocmds.lua` (see the Python `\x` mapping)
- Install language servers/formatters in `../configuration.nix`, never via Mason

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
