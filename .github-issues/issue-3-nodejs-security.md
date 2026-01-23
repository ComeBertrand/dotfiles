# 🔴 CRITICAL: Remove Node.js 14 (End-of-Life Security Vulnerability)

**Labels:** security

## Problem

Configuration explicitly allows insecure `nodejs-14.21.3`:

```nix
nixpkgs.config.permittedInsecurePackages = [
  "nodejs-14.21.3"
  "nodejs_14"
];
```

**Node.js 14 reached EOL in April 2023** - that's nearly 3 years ago! It receives NO security updates and has multiple known CVEs that will never be patched. In 2026, this is a serious security risk.

## Impact

- ⚠️ Actively vulnerable to known exploits (CVE-2025-23167 and others)
- ⚠️ Compliance violations if handling any sensitive data
- ⚠️ Supply chain security risk for your entire stack
- ⚠️ Sets bad precedent for "technical debt is acceptable"

## Action Plan

**Priority: CRITICAL - Fix immediately**

### 1. Identify what requires Node.js 14

```bash
grep -r "node" configuration.nix sources/
# Check which projects/tools need old Node
```

### 2. Upgrade path options

- **Best:** Node.js 22 LTS (active until April 2027) - future-proof
- **Good:** Node.js 20 LTS (maintenance mode)
- **Last resort:** Containerize legacy apps requiring Node 14

### 3. Remove insecure package allowance

```nix
# DELETE these lines from configuration.nix
nixpkgs.config.permittedInsecurePackages = [
  "nodejs-14.21.3"
  "nodejs_14"
];
```

### 4. Add modern Node

```nix
environment.systemPackages = with pkgs; [
  nodejs_22  # or nodejs_20
];
```

### 5. Test affected projects

Update package.json engines field

## Sources

- [Node.js End-Of-Life](https://nodejs.org/en/about/eol)
- [endoflife.date - Node.js](https://endoflife.date/nodejs)
- [Node.js CVE for EOL versions](https://nodejs.org/en/blog/vulnerability/upcoming-cve-for-eol-versions)

## Estimated Effort

1-2 hours

## Implementation Order

Week 1: Security & Foundation (URGENT)
