# 🟡 Add mise for runtime version management

**Labels:** enhancement

## Problem

Currently using system-wide Python 3.12, Rust, and Node.js versions. While `uv` handles Python package management well, we can't:

- Run different Python versions per project (e.g., legacy 3.10 project + modern 3.12 project)
- Test against multiple Node.js versions
- Quickly switch Rust toolchains
- Match production environments exactly

## Impact

- "Works on my machine" problems
- Can't maintain legacy projects alongside modern ones
- No per-project `.tool-versions` file for team consistency
- Manual NixOS rebuilds just to change language versions

## Action Plan

**Priority: MEDIUM - Quality of life improvement**

### 1. Add `mise` (formerly rtx) to configuration.nix

```nix
users.users.cbertrand.packages = with pkgs; [
  mise  # Fast Rust-based, replaces asdf
];
```

### 2. Enable mise in bashrc

```bash
# In sources/bashrc.sh
eval "$(mise activate bash)"
```

### 3. Configure mise for auto-installation

```bash
# ~/.config/mise/config.toml
[tools]
python = "3.12"
node = "22"
rust = "1.75"

[settings]
experimental = true
```

### 4. Per-project versions using `.mise.toml`

```toml
[tools]
python = "3.10.12"  # Legacy project
node = "20.11.0"
```

### 5. Keep NixOS packages as fallback

mise can reference system versions

## Why mise over asdf

- 24x faster (Rust vs bash)
- Built-in Python/Node support (no plugins needed)
- Replaces direnv for environment variables
- ~5ms overhead vs ~120ms for asdf

## Sources

- [Better Stack - mise vs asdf](https://betterstack.com/community/guides/scaling-nodejs/mise-vs-asdf/)
- [Medium - Why I switched to mise](https://medium.com/@nidhivya18_77320/why-i-switched-from-asdf-to-mise-and-you-should-too-8962bf6a6308)
- [mise documentation](https://mise.jdx.dev/dev-tools/)

## Estimated Effort

2-3 hours

## Implementation Order

Week 2: Developer Experience
