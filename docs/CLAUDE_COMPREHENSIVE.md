# CLAUDE.md - AI Assistant Guide for NixOS Dotfiles Repository

**Last Updated:** 2026-08-03
**Repository Owner:** Come Bertrand
**NixOS Version:** 26.05 (flake-based)
**System State Version:** 23.05 (first-install marker — do not bump)

> Companion documents: [CLAUDE.md](../CLAUDE.md) for quick change recipes,
> [README.md](../README.md) for the step-by-step install manual.

---

## Table of Contents

1. [Repository Overview](#repository-overview)
2. [Codebase Structure](#codebase-structure)
3. [Key Files Reference](#key-files-reference)
4. [Development Workflow](#development-workflow)
5. [Flake Conventions](#flake-conventions)
6. [Editor Configuration](#editor-configuration)
7. [Git Conventions](#git-conventions)
8. [Maintenance Procedures](#maintenance-procedures)
9. [AI Assistant Guidelines](#ai-assistant-guidelines)
10. [Quick Reference](#quick-reference)

---

## Repository Overview

A **NixOS dotfiles repository** managing system-wide and user-specific configuration for a
development workstation, built on **Nix flakes** (not channels). It uses:

- **NixOS 26.05** for declarative system configuration
- **Home Manager** (`release-26.05`, wired as a flake input) for user dotfiles
- **i3 window manager** as the desktop environment
- **Neovim** as the primary editor (native LSP, Treesitter, lazy.nvim)
- **Vim** retained as a fallback editor (ALE-based)
- **kitty** as the terminal, with **zellij** as multiplexer
- **Bash** as the default shell, with direnv
- **Docker** for containerization
- **Kubernetes tooling** (kubectl, helm, k9s, telepresence2)
- **Syncthing** for file sync between machines

### Primary Use Cases
- Python development (pyright, ruff)
- Rust development (rust-analyzer via rustaceanvim, rustfmt)
- TypeScript development (ts_ls, eslint, prettier)
- Kubernetes cluster management
- AWS cloud infrastructure work
- LLM coding agents (claude-code, codex, tam)

---

## Codebase Structure

```
/home/cbertrand/dotfiles/
├── flake.nix                      # Flake inputs & outputs (nixosConfigurations.wiremind)
├── flake.lock                     # Pinned input versions — ALWAYS COMMIT
├── configuration.nix              # Main NixOS system configuration
├── hardware-configuration.nix     # Machine-specific, auto-generated (DON'T EDIT)
├── gpu.nix                        # NVIDIA/Intel hybrid graphics — currently DISABLED
│                                  #   (commented out in configuration.nix imports:
│                                  #    GPU hardware defect, VBIOS unreadable)
├── CLAUDE.md                      # Quick change recipes
├── README.md                      # Step-by-step install manual
├── nix-work/default.nix           # Optional work module stub (override the input)
├── docs/CLAUDE_COMPREHENSIVE.md   # This file
│
├── recrank.sh                     # Rebuild & switch (flake-based)
├── upgrade.sh                     # nix flake update + rebuild
├── cleanup.sh                     # GC generations older than 15 days
├── cleanup-hard.sh                # GC everything unreferenced
│
└── sources/                       # All dotfiles live here
    ├── CLAUDE.md                  # Notes scoped to this directory
    ├── config.nix                 # User-level nixpkgs config
    ├── zen.nix                    # Zen browser Home Manager module (declarative extensions)
    │
    ├── nvim/                      # PRIMARY editor
    │   ├── init.lua               # Entry point
    │   └── lua/
    │       ├── config/
    │       │   ├── options.lua    # Core settings
    │       │   ├── keymaps.lua    # Global keymaps
    │       │   ├── autocmds.lua   # Autocommands (incl. Python \x pudb mapping)
    │       │   └── lsp.lua        # Diagnostics + on-attach LSP keymaps
    │       └── plugins/init.lua   # lazy.nvim plugin specs & configuration
    ├── vimrc                      # FALLBACK editor (ALE, vim-plug, Copilot)
    │
    ├── bashrc.sh                  # Interactive shell
    ├── bash_profile.sh            # Login shell
    ├── bash_prompt.sh             # Prompt
    ├── path.sh                    # PATH (~/.local/bin) + TMPDIR (~/.local/tmp)
    ├── aliases.sh                 # Shell aliases
    ├── direnvrc.sh                # direnv custom functions
    ├── direnv.toml                # direnv config (auto-allow Workspace)
    ├── gitconfig.conf             # Git identity + `tree` alias
    ├── gpg-agent.conf             # GPG agent
    ├── i3config.conf              # i3 window manager
    ├── kitty.conf                 # Terminal
    ├── rofi-config.rasi           # Application launcher
    ├── zellij.kdl                 # Multiplexer config
    ├── zellij-layout.kdl          # Default layout
    ├── zellij-layout-dev.kdl      # Dev layout (nvim + two terminals)
    ├── yazi.toml                  # File manager
    ├── yazi_keymap.toml           # File manager keymaps
    ├── tam-config.toml            # Terminal agent multiplexer
    ├── claude-settings.json       # Claude Code user settings
    │
    └── scripts/                   # Symlinked to ~/.local/bin
        ├── screenz                # Auto-configure monitors
        ├── startdm                # Start X11/i3 (REQUIRED — autorun disabled)
        ├── switchkb               # Toggle US/FR keyboard layouts
        ├── nixinit                # Scaffold .envrc + shell.nix + git excludes
        ├── dcs                    # Docker Compose services helper
        ├── k9                     # Pick a process with fzf and kill it
        ├── dev-open               # Open kitty + zellij session for a directory
        ├── tam-open               # Pick a project via rofi, launch dev session
        └── morning                # Startup housekeeping (systemd user service)
```

---

## Key Files Reference

### Core NixOS Configuration

#### `flake.nix`
**Purpose:** Entry point. Defines inputs and the `nixosConfigurations.wiremind` output.

**Inputs:**

| Input | Purpose |
|---|---|
| `nixpkgs` | NixOS 26.05 stable |
| `nixpkgs-unstable` | Bleeding-edge packages, imported with `allowUnfree` |
| `home-manager` | `release-26.05`, follows `nixpkgs` |
| `llm-agents` | claude-code and friends (Numtide, daily-updated, binary cache) |
| `tam` | Terminal agent multiplexer |
| `zen-browser` | Zen browser + hardened HM module (follows `nixpkgs-unstable`) |
| `firefox-addons` | rycee NUR add-ons, hash-pinned for Zen |
| `nix-work` | Optional work module, `flake = false`, defaults to the in-repo stub |

**Passed to modules via `specialArgs`:** `pkgs-unstable`, `llmPkgs`, `tamPkg`.
Flake `inputs` are forwarded to Home Manager via `extraSpecialArgs` (needed by `zen.nix`).

#### `configuration.nix`
**Purpose:** Main system configuration.

**Key areas:** boot (systemd-boot + EFI, `configurationLimit = 5`), kernel pinning,
hostname/networking (NetworkManager + systemd-resolved), locale, X11 + i3, pipewire,
Docker, user account, Home Manager `home.file` links, Syncthing, nix settings, firewall.

**Important notes:**
- Home Manager is wired via flake — **no channel required**
- Work module is an optional flake input (stub by default; override to `../nix-work`)
- X11 autorun disabled — requires manual `startdm`
- `pkgs-unstable.*` for bleeding-edge packages (zellij, uv, yazi, codex, flyctl, rust-analyzer)
- Kernel is pinned to `linuxPackages_latest` for CVE-2026-31431; see the inline comment
  before changing (the 6.18 line had an iwlwifi/AX211 regression)

#### `hardware-configuration.nix`
**Purpose:** Auto-generated hardware detection. Pins filesystem UUIDs and the LUKS device.
**Convention:** DO NOT edit. Regenerate with
`sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix`.
Machine-specific — reusing it on other hardware produces an unbootable system.

#### `sources/config.nix`
**Purpose:** User-level nixpkgs configuration. Mirrors `permittedInsecurePackages` so
user-level `nix` commands behave like the system.

#### `sources/zen.nix`
**Purpose:** Zen browser Home Manager module. Extensions are **declarative** —
uBlock Origin, Bitwarden and ClearURLs come from the `firefox-addons` NUR; Proton Pass and
Proton VPN are force-installed via `policies.ExtensionSettings` because they are not
packaged there. Plain `firefox` is also installed but is *not* configured declaratively.

### Services

#### Syncthing
Declared in `configuration.nix`, runs as `cbertrand:users` with config in
`~/.config/syncthing` and the web UI bound to `127.0.0.1:8384` (never exposed to the LAN).
`openDefaultPorts = true` opens 22000/tcp+udp and 21027/udp.

**Peers are managed through the `syncthingPeers` attrset in the `let` block at the top of
`configuration.nix`** — devices and both folders' share lists derive from it, so it is the
only place to edit. `overrideDevices`/`overrideFolders` are `true`, meaning devices or
folders added through the web UI are **deleted on the next rebuild**.

Folders (IDs must match across machines; paths may differ):

| ID | Path | Notes |
|---|---|---|
| `documents` | `~/Documents` | trashcan versioning, 30 days |
| `workspace` | `~/Workspace` | trashcan versioning + `ignorePatterns` |

The `workspace` ignore patterns (`.venv`, `node_modules`, `target`, `.direnv`, caches,
Nix `result` symlinks) cut it from ~103 G to ~4 G. Add any new build directory there.
Patterns are applied through Syncthing's REST API on rebuild.

Note that `overrideDevices = true` also means **pairing cannot be done in the GUI** — it
must go through the repo. See README section 5.4 for the full pairing flow.

#### `morning` (systemd user service)
Runs `~/.local/bin/morning` at login (`Type = oneshot`, wanted by `default.target`).
Purges dead zellij sessions.

### Shell Configuration

| File | Purpose |
|---|---|
| `sources/bashrc.sh` | Interactive shell: direnv hook, SSH agent auto-start, ls aliases |
| `sources/bash_profile.sh` | Login shell: sources `.path`, `.aliases`, `.bash_prompt` |
| `sources/path.sh` | Prepends `~/.local/bin`; sets `TMPDIR=~/.local/tmp` |
| `sources/aliases.sh` | Shell aliases |
| `sources/gitconfig.conf` | Git identity and the `tree` alias |

---

## Development Workflow

### Making Configuration Changes

1. **Edit** `configuration.nix` or files under `sources/`.

2. **`git add` any new file.** Flakes only evaluate **git-tracked** files, so an untracked
   new file is invisible and produces confusing "file not found" errors:
   ```bash
   git add sources/myapp.toml
   ```

3. **Verify it builds without switching** — the safest pre-commit check:
   ```bash
   nix build .#nixosConfigurations.wiremind.config.system.build.toplevel --no-link
   ```
   Or evaluate a single option to inspect the result:
   ```bash
   nix eval .#nixosConfigurations.wiremind.config.services.syncthing.settings --json
   ```
   Add `--override-input nix-work path:../nix-work` when the work module is present
   (`recrank.sh` does this automatically).

4. **Apply:**
   ```bash
   ./recrank.sh
   ```

5. **Verify** services are running, packages resolve, and Home Manager symlinks landed.

6. **Commit** following the conventions below.

### Adding New Packages

| Scope | Location |
|---|---|
| User only | `users.users.cbertrand.packages` |
| All users | `environment.systemPackages` |
| Bleeding-edge | prefix with `pkgs-unstable.` |
| LLM agents | `llmPkgs.<name>` (from the `llm-agents` input) |

Unfree packages are already allowed via `nixpkgs.config.allowUnfree`. Insecure packages go
in `nixpkgs.config.permittedInsecurePackages` **and** `sources/config.nix`.

### Adding New Dotfiles

1. Create the source file in `sources/`
2. `git add` it
3. Link under `home-manager.users.cbertrand.home.file`:
   ```nix
   ".config/myapp/config.toml" = {
     source = ./sources/myapp.toml;
   };
   ```
4. `./recrank.sh`

---

## Flake Conventions

This repo migrated from channels to flakes. **`nix-channel` plays no role** — any
instruction to add or update a channel is obsolete. Input versions are pinned in
`flake.lock`.

### Updating Inputs

```bash
nix flake update          # refresh all inputs in flake.lock
./upgrade.sh              # nix flake update + rebuild + switch
nix flake metadata        # inspect what is currently pinned
```

**Always commit `flake.lock`.** It is what makes builds reproducible.

### Upgrading NixOS Version

Bump `nixpkgs` and `home-manager` **together** — they must stay on the same release:

```nix
nixpkgs.url = "github:NixOS/nixpkgs/nixos-XX.XX";
home-manager.url = "github:nix-community/home-manager/release-XX.XX";
```

```bash
nix flake update
./recrank.sh
sudo reboot
```

Leave `system.stateVersion` at `23.05` — it records the release this machine was *first*
installed with, not the current one. Changing it can badly migrate stateful services.

### Nix Language Patterns

**Unstable packages** come from `specialArgs`, not a channel import:
```nix
{ config, pkgs, pkgs-unstable, llmPkgs, tamPkg, ... }:

environment.systemPackages = [ pkgs-unstable.yazi llmPkgs.claude-code tamPkg ];
```

**Let-in for derived values** (see the `syncthingPeers` pattern in `configuration.nix`):
```nix
let
  peers = { laptop = "DEVICE-ID"; };
  peerNames = builtins.attrNames peers;
in
{ ... }
```

**Deriving an attrset from another:**
```nix
devices = builtins.mapAttrs (_name: id: { inherit id; }) peers;
```

**List concatenation:** `[ a b ] ++ [ c ]` — note that NixOS *merges* list-typed options
across modules, which is why `services.syncthing.openDefaultPorts` can add firewall ports
alongside an explicit `networking.firewall.allowedTCPPorts = [ ]`.

---

## Editor Configuration

### Neovim (primary)

**Plugin manager:** lazy.nvim (auto-installs on first launch). `:Lazy` opens the UI;
`:Lazy restore` pins back to the lockfile, `:Lazy sync` installs/updates.

**LSP:** native, configured with the modern `vim.lsp.config()` / `vim.lsp.enable()` API in
`sources/nvim/lua/plugins/init.lua`. Servers enabled: **pyright**, **ts_ls**, **lua_ls**.
Rust is handled separately by **rustaceanvim**, which manages rust-analyzer itself — do
not also declare it via lspconfig.

Shared diagnostics config and the on-attach keymaps live in
`sources/nvim/lua/config/lsp.lua`.

**Formatting** — conform.nvim:

| Filetype | Formatter |
|---|---|
| python | `ruff_format`, `ruff_fix` |
| rust | `rustfmt` |
| ts/tsx/js/jsx/json/yaml/html/css | `prettier` |
| lua | `stylua` |

**Linting** — nvim-lint: `ruff` (python), `eslint` (ts/tsx/js/jsx), triggered on
`BufWritePost`, `BufReadPost`, `InsertLeave`.

**Notable plugins:** telescope (+fzf-native), yazi.nvim (file manager), aerial.nvim (code
outline), gitsigns, treesitter, nvim-cmp (+LuaSnip), neotest (+neotest-python), lualine,
which-key, Comment.nvim, nvim-surround, fidget, render-markdown, rainbow-delimiters,
gruvbox.

**Keymaps** (leader = `\`):

| Key | Action |
|---|---|
| `\f` / `\F` | Telescope git files / all files |
| `\g` | Live grep |
| `;` | Buffers |
| `\n` | Open yazi at current file |
| `\s` | Toggle code outline (aerial) |
| `\b` / `\r` / `\R` / `\a` / `K` | Definition / references / rename / code action / hover |
| `gD` / `gi` / `\D` / `\k` | Declaration / implementation / type definition / signature help |
| `\tn` / `\tf` / `\ts` / `\tl` | neotest: nearest / file / suite / last |
| `\th` / `\tv` | Open terminal in horizontal / vertical split |
| `\hs` / `\hu` / `\hp` / `\hb` | Gitsigns: stage / undo / preview hunk, blame line |
| `\w{h,v,e,l,r}` | Window sizing (also mapped in terminal mode) |
| `\z` | Toggle zellij pane fullscreen from inside nvim |
| `\cp` | Copy relative file path to clipboard |
| `\x` | Insert `pudb` breakpoint (Python buffers only, set in `autocmds.lua`) |
| `Ctrl+H/J/K/L` | Navigate splits (zellij-aware) |

### Vim (fallback)

`sources/vimrc` is kept working as a fallback: vim-plug, **ALE** for linting/fixing,
fugitive + gitgutter, FZF, Tagbar, vim-test, and GitHub Copilot (`:Copilot setup`,
requires Node.js). Same leader (`\`) and broadly parallel keybindings.

```vim
:PlugInstall  :PlugUpdate  :PlugClean  :ALEInfo
```

### Adding a Language

1. Install the server/linter/formatter in `configuration.nix`
2. **Neovim:** add `vim.lsp.config("<server>", {...})` and append the server to the
   `vim.lsp.enable` loop in `plugins/init.lua`; add entries to `formatters_by_ft` /
   `linters_by_ft`
3. **Vim:** add to `g:ale_linters` and `g:ale_fixers` in `sources/vimrc`

---

## Git Conventions

### Commit Message Format

**Pattern:** `<type>: <description>`

`feat:` new functionality · `fix:` bug fix · `chore:` maintenance · `docs:` documentation ·
`refactor:` restructuring without behavior change

**Examples from history:**
```
feat: add vim-test to vimrc
feat: use uv as a python package manager
chore: remove aider stuff
fix: fix yazi following move to 26.05
chore: upgrade NixOS 25.11 → 26.05
```

### Branching

Main branch is `master`. Use descriptive feature branch names; don't commit or push unless
asked.

### Tools

- `git tree` — visual commit graph with colors and dates (defined in `gitconfig.conf`)
- Neovim: gitsigns (`]h`/`[h` to navigate hunks, `\hs`/`\hu`/`\hp`/`\hb`)
- Vim: fugitive + gitgutter

### Recovering From a Bad Amend

An accidental `git commit --amend` that should have been a new commit is recoverable while
unpushed — the pre-amend commit is still in the reflog:

```bash
git reflog                    # find the pre-amend commit
git reset --soft <pre-amend>  # restore HEAD, keep the delta staged
git commit -m "..."           # commit it separately
```

---

## Maintenance Procedures

### System Cleanup

```bash
./cleanup.sh        # nix-collect-garbage --delete-older-than 15d
./cleanup-hard.sh   # nix-collect-garbage -d  (use with caution)
```

Note `boot.loader.systemd-boot.configurationLimit = 5` already caps boot entries.

### Rollback

```bash
sudo nixos-rebuild switch --rollback --flake .#wiremind
# or pick a previous generation in the boot menu

git checkout HEAD~1 -- flake.lock && ./recrank.sh   # revert a bad input update
```

### SSH Key Setup

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -a 100 -t ed25519 -C "come.bertrand@protonmail.com"
```

Then register the public key with GitHub/GitLab.

### Monitoring & Debugging

`htop`, `k9s`, `nix-tree`, `visidata`, `kcachegrind` + `graphviz`, `dmidecode`.

```bash
nix flake check                        # evaluate for errors
systemctl status syncthing.service     # service state
journalctl -u syncthing -e             # service logs
:checkhealth / :LspInfo                # inside Neovim
```

---

## AI Assistant Guidelines

### When Modifying Configuration

1. **Read files before editing.** Understand current state first.
2. **Preserve declarative patterns.** Never suggest imperative package installs;
   everything goes through `configuration.nix`.
3. **`git add` new files** or the flake won't see them.
4. **Verify before claiming success.** Prefer
   `nix build .#nixosConfigurations.wiremind.config.system.build.toplevel --no-link`, which
   needs no sudo, over asserting that a change "should work". `./recrank.sh` requires an
   interactive sudo password and generally cannot be run unattended.
5. **Follow existing conventions:** 2-space indent in `.nix`, inline comments explaining
   *why*, grouped by functional area.
6. **Be cautious with system-critical files:** `hardware-configuration.nix`, boot loader
   settings, the pinned kernel, user groups.

### Understanding User Context

**System details:**
- **Hostname:** wiremind · **User:** cbertrand (`users`, `wheel`, `networkmanager`, `docker`)
- **Timezone:** Europe/Paris · **Locale:** en_US.UTF-8 with FR regional settings
- **Window Manager:** i3 (manual start via `startdm`)
- **Terminal:** kitty + zellij
- **Editor:** Neovim primary, Vim fallback

**Common tasks:** Python development, Kubernetes operations, AWS, Rust development,
LLM agent workflows.

### Code Style Preferences

- **Nix:** inline comments for non-obvious settings, grouped by functional area, explicit
  over implicit
- **Neovim Lua:** organized into `config/` and `plugins/`, section header comments
- **Vim:** heavy inline documentation, logical sections, quick-reference cards
- **Shell scripts:** `set -euo pipefail`, simple and direct, `--verbose` where useful

### Security Considerations

1. **Permitted insecure packages** are intentional (`nodejs-14` for legacy projects)
2. **Docker access** granted to the user (docker group is root-equivalent)
3. **SSH agent** auto-starts in `bashrc`; **GPG agent** configured for signing
4. **Secrets** via `infisical`; never commit keys or tokens
5. **Syncthing device IDs are NOT secrets** — they are public identifiers and belong in
   the repo. API keys in `~/.config/syncthing/config.xml` are secret and stay out.
6. **Syncthing web UI** is bound to localhost only; do not add 8384 to the firewall

### External Dependencies

**Optional (work-only):** `../nix-work` — override the `nix-work` input; the repo ships a
no-op stub, and `recrank.sh`/`upgrade.sh` auto-override when `../nix-work` exists.

**Managed by flake inputs (no channels):** nixpkgs 26.05, nixpkgs-unstable,
home-manager release-26.05, llm-agents, tam, zen-browser, firefox-addons.

**Binary cache:** `cache.numtide.com` is configured as an extra substituter for
llm-agents packages.

### Common Pitfalls to Avoid

1. **DON'T forget to `git add` new files** — flakes only see git-tracked files. This is the
   single most common source of confusing errors in this repo.
2. **DON'T suggest `nix-channel`** — this repo is flake-based; channels do nothing here.
3. **DON'T assume `~/.local/bin` is on PATH in i3 keybindings.** It is set by `path.sh` for
   shells, but i3 does not inherit it — bindings need full paths like
   `~/.local/bin/screenz`. Nix-managed binaries in
   `/etc/profiles/per-user/cbertrand/bin/` are fine unqualified.
4. **DON'T bump `system.stateVersion`** — it is a first-install marker.
5. **DON'T edit `hardware-configuration.nix`** — auto-generated and machine-specific.
6. **DON'T use `-uall` with `git status`** — can exhaust memory on large repos.
7. **DON'T pair Syncthing devices in the web UI** — `overrideDevices = true` wipes them on
   rebuild; edit `syncthingPeers` instead.
8. **DON'T use interactive flags** (`-i`) with git commands; they are unsupported here.

### Helpful Patterns

**Adding a system package:**
```nix
# configuration.nix → environment.systemPackages
environment.systemPackages = with pkgs; [
  existing-package
  new-package  # Brief description
];
```

**Adding a user package:**
```nix
# configuration.nix → users.users.cbertrand.packages
packages = with pkgs; [
  existing-package
  new-package  # Brief description
];
```

**Adding a Neovim plugin:**
```lua
-- sources/nvim/lua/plugins/init.lua — add to the returned table
{
  "author/plugin-name",
  config = function()
    require("plugin-name").setup({})
  end,
},
```

**Adding a Vim plugin:**
```vim
" sources/vimrc, Section 9
Plug 'author/plugin-name'  " Description
" Then configure in Section 11
let g:plugin_setting = value
```

### Response Format Preferences

- Be concise but complete
- Reference files and options by name (`configuration.nix:407`, `services.syncthing`)
- Provide ready-to-run commands with real paths, not placeholders
- Explain NixOS-specific concepts (declarative, flakes, generations, closures)
- State what was actually verified versus what is expected

---

## Quick Reference

### Essential Commands

| Command | Purpose |
|---|---|
| `./recrank.sh` | Rebuild and switch (needs interactive sudo) |
| `./upgrade.sh` | `nix flake update` + rebuild |
| `nix flake update` | Update inputs only |
| `nix flake check` | Evaluate for errors |
| `nix flake show` / `metadata` | Inspect outputs / pinned inputs |
| `nix build .#nixosConfigurations.wiremind.config.system.build.toplevel --no-link` | Build without switching |
| `sudo nixos-rebuild switch --flake .#wiremind` | Manual rebuild |
| `./cleanup.sh` / `./cleanup-hard.sh` | Garbage collection |
| `startdm` | Start X11/i3 (**required**) |
| `screenz` | Configure monitors |
| `switchkb` | Toggle US/FR keyboard |
| `nixinit <python\|rust\|node>` | Scaffold project `.envrc` + `shell.nix` |
| `syncthing --home=$HOME/.config/syncthing device-id` | Print this machine's Syncthing ID |

### Key File Locations

| File | Purpose |
|---|---|
| `/home/cbertrand/dotfiles/flake.nix` | Flake inputs & outputs |
| `/home/cbertrand/dotfiles/configuration.nix` | Main system config |
| `/home/cbertrand/dotfiles/sources/nvim/` | Neovim config (primary editor) |
| `/home/cbertrand/dotfiles/sources/vimrc` | Vim config (fallback) |
| `/home/cbertrand/dotfiles/sources/i3config.conf` | i3 window manager |
| `~/.config/nvim` | Neovim config (symlink) |
| `~/.config/git/config` | Git config (symlink) |
| `~/.config/syncthing/config.xml` | Syncthing state — contains a secret API key |
| `~/.local/bin/*` | Custom scripts (symlinked) |
| `~/.local/tmp` | `TMPDIR` |

### Important URLs

- NixOS Manual: https://nixos.org/manual/nixos/stable/
- NixOS option search: https://search.nixos.org/options
- Home Manager: https://github.com/nix-community/home-manager
- Home Manager options: https://nix-community.github.io/home-manager/options.xhtml
- NixOS version upgrade: https://nixos.org/manual/nixos/stable/index.html#sec-upgrading
- Syncthing ignore syntax: https://docs.syncthing.net/users/ignoring.html
- lazy.nvim: https://github.com/folke/lazy.nvim

---

## Version History

- **2026-01-23:** Initial CLAUDE.md creation
- **2026-08-03:** Rewritten for accuracy — flakes replace channels throughout, Neovim
  documented as the primary editor, kitty replaces URxvt, Syncthing documented, removed
  stale references (`setexclude`, `xresources`, `rxvt-resize-font`, LaTeX, Home Manager
  channel install, manual Firefox extensions), corrected `k9` description

---

## Notes for Future Updates

When updating this document:
1. Update "Last Updated" at the top and add a Version History entry
2. Verify the NixOS version against `flake.nix`, not memory
3. **Re-check claims against the files** — the previous revision drifted badly by
   describing intent rather than the current state. Grep before asserting.
4. Verify external URLs still resolve
5. Keep this document in sync with `../CLAUDE.md` and `../README.md`

---

**End of CLAUDE.md**
