# GitHub Issues - Codebase Improvement Plan

This directory contains 5 GitHub issue templates based on the comprehensive codebase analysis conducted on 2026-01-23.

## Issues Summary

1. **🔴 CRITICAL: Nix Flakes Migration** (`issue-1-nix-flakes.md`)
   - Priority: HIGH
   - Effort: 4-6 hours
   - Impact: Reproducible builds, version pinning

2. **🔴 HIGH: Vim to Neovim Migration** (`issue-2-neovim-migration.md`)
   - Priority: MEDIUM-HIGH
   - Effort: Ongoing (gradual)
   - Impact: Modern LSP, better performance, Lua plugins

3. **🔴 CRITICAL: Node.js 14 Security Fix** (`issue-3-nodejs-security.md`)
   - Priority: CRITICAL ⚠️
   - Effort: 1-2 hours
   - Impact: Security vulnerability, EOL software
   - Label: `security`

4. **🟡 Add mise Version Manager** (`issue-4-mise-version-manager.md`)
   - Priority: MEDIUM
   - Effort: 2-3 hours
   - Impact: Per-project runtime versions
   - Label: `enhancement`

5. **🟡 Home Manager Flake Pattern** (`issue-5-home-manager-flake.md`)
   - Priority: MEDIUM
   - Effort: Automatic (depends on #1)
   - Impact: Better version control integration
   - Label: `enhancement`

## How to Create Issues

### Option 1: GitHub CLI (gh)

Once `gh` is installed on your NixOS system (already added to configuration.nix):

```bash
# After running ./recrank.sh to install gh
cd /path/to/dotfiles

# Create each issue
gh issue create --title "$(head -n 1 .github-issues/issue-1-nix-flakes.md | sed 's/^# //')" --body "$(tail -n +3 .github-issues/issue-1-nix-flakes.md)"
gh issue create --title "$(head -n 1 .github-issues/issue-2-neovim-migration.md | sed 's/^# //')" --body "$(tail -n +3 .github-issues/issue-2-neovim-migration.md)"
gh issue create --title "$(head -n 1 .github-issues/issue-3-nodejs-security.md | sed 's/^# //')" --body "$(tail -n +3 .github-issues/issue-3-nodejs-security.md)" --label security
gh issue create --title "$(head -n 1 .github-issues/issue-4-mise-version-manager.md | sed 's/^# //')" --body "$(tail -n +3 .github-issues/issue-4-mise-version-manager.md)" --label enhancement
gh issue create --title "$(head -n 1 .github-issues/issue-5-home-manager-flake.md | sed 's/^# //')" --body "$(tail -n +3 .github-issues/issue-5-home-manager-flake.md)" --label enhancement
```

### Option 2: Manual Creation via GitHub Web UI

1. Go to https://github.com/ComeBertrand/dotfiles/issues/new
2. Copy the title (first line without `#`) from each markdown file
3. Copy the body (everything after the first line) into the issue description
4. Add labels as noted in the file
5. Click "Submit new issue"

### Option 3: Bulk Script

```bash
#!/usr/bin/env bash
for file in .github-issues/issue-*.md; do
  title=$(head -n 1 "$file" | sed 's/^# //')
  body=$(tail -n +3 "$file")

  # Extract labels if mentioned
  labels=""
  if grep -q "security" "$file"; then
    labels="--label security"
  elif grep -q "enhancement" "$file"; then
    labels="--label enhancement"
  fi

  gh issue create --title "$title" --body "$body" $labels
done
```

## Recommended Implementation Order

```
Week 1: Security & Foundation
├── Issue #3: Node.js 14 security fix (URGENT - 1-2 hours)
└── Issue #1: Nix Flakes migration (4-6 hours)

Week 2: Developer Experience
└── Issue #4: mise version manager (2-3 hours)

Week 3-4: Major Migration
├── Issue #2: Vim → Neovim (ongoing, gradual)
└── Issue #5: Home Manager flake (automatic from #1)
```

## Analysis Source

These issues were generated from a comprehensive codebase analysis against 2026 best practices, including:
- Web research on modern NixOS patterns (Flakes)
- Comparison of Vim vs Neovim ecosystem
- Security audit of dependencies
- Developer tooling best practices (mise, uv, ruff)

Full analysis available in the session: https://claude.ai/code/session_01VLQzrmwQ7bZGKbzbJfxqGQ
