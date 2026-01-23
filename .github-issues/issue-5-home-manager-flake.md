# 🟡 Update Home Manager to use flake input pattern

**Labels:** enhancement

## Problem

Home Manager is currently installed as a NixOS module via channels:

```nix
imports = [ <home-manager/nixos> ];
```

This is the old pattern. Modern approach (2026) treats Home Manager as a flake input with version pinning.

## Impact

- Home Manager version separate from system config version control
- Can't pin Home Manager to specific commit
- Harder to test Home Manager updates independently
- Doesn't follow "inputs.nixpkgs.follows" pattern for version alignment

## Action Plan

**Priority: MEDIUM - Do after flakes migration (#1)**

### 1. This becomes automatic once you migrate to flakes

See issue #1 for flakes migration

### 2. In flake.nix, ensure version alignment

```nix
home-manager = {
  url = "github:nix-community/home-manager/release-24.05";
  inputs.nixpkgs.follows = "nixpkgs";  # Critical: prevents version mismatch
};
```

### 3. Update configuration.nix

```nix
# Remove:
# imports = [ <home-manager/nixos> ];

# Keep home-manager.users.cbertrand config as-is
```

### 4. Benefit: Single `flake.lock` pins everything

nixpkgs + home-manager + unstable all pinned in version control

## Sources

- [NixOS & Flakes Book - Home Manager setup](https://nixos-and-flakes.thiscute.world/nixos-with-flakes/start-using-home-manager)
- [NixOS Discourse - Home Manager via flake](https://discourse.nixos.org/t/set-up-nixos-home-manager-via-flake/29710)

## Dependencies

- Depends on #1 (Nix Flakes migration)

## Estimated Effort

Automatic from flakes migration (included in 4-6 hours)

## Implementation Order

Week 1: Security & Foundation (after flakes migration)
