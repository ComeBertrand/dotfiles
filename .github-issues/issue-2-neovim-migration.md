# 🔴 HIGH: Migrate from Vim to Neovim for modern development

## Problem

In 2026, Neovim has become the standard for modern development:

- **Native LSP support** - Current setup uses ALE as a workaround for LSP, but Neovim has built-in LSP
- **Lua-based plugins** - Faster, better ecosystem, easier to configure than VimScript
- **Better performance** - "Neovim just feels snappier. Less lag, smoother scrolling, faster responsiveness"
- **Active development** - Vim's development is much slower

The current 2,500-line vimrc is impressive but uses outdated architecture (ALE for LSP, VimScript configuration).

## Impact

- Missing native treesitter for better syntax highlighting and code understanding
- Slower plugin ecosystem (VimScript vs Lua)
- More complex configuration (ALE layer vs native LSP)
- Missing modern features (floating windows, better terminal integration)

## Action Plan

**Priority: MEDIUM-HIGH - Significant but requires migration effort**

### 1. Add Neovim to configuration.nix

```nix
users.users.cbertrand.packages = with pkgs; [
  neovim  # Replace vim_configurable
];
```

### 2. Migrate incrementally using init.lua

- Start with `~/.config/nvim/init.lua` that sources your existing vimrc
- Gradually migrate sections to Lua-based config
- Replace ALE with native LSP: `nvim-lspconfig`, `nvim-cmp` for completion

### 3. Modern plugin manager

Replace vim-plug with `lazy.nvim` (lazy loading, better performance)

### 4. Add treesitter for superior syntax highlighting

```lua
require('nvim-treesitter.configs').setup {
  ensure_installed = { "python", "rust", "typescript", "lua" },
  highlight = { enable = true },
}
```

### 5. Keep Vim as fallback during transition

Don't remove immediately - allow gradual migration

## Sources

- [Slant - Vim vs Neovim detailed comparison](https://www.slant.co/versus/42/62/~vim_vs_neovim)
- [Geekflare - Neovim vs Vim](https://geekflare.com/dev/neovim-vs-vim-comparison/)
- [Medium - NeoVim from scratch in 2025](https://medium.com/@edominguez.se/so-i-switched-to-neovim-in-2025-163b85aa0935)

## Estimated Effort

Ongoing (can be gradual over weeks)

## Implementation Order

Week 3-4: Major Migration (can be gradual)
