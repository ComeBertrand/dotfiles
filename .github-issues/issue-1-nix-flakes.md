# 🔴 CRITICAL: Migrate to Nix Flakes for reproducible builds

## Problem

Currently using legacy channel-based NixOS configuration with `sudo nix-channel --update`. In 2026, this approach has major reproducibility issues:

- Channel updates can't be rolled back to specific commits
- No guarantee two machines get the same package versions
- Dependencies aren't pinned in version control
- Configuration and nixpkgs versions are separate (manual coordination required)

## Impact

- Team members can't reliably reproduce your environment
- System rebuilds after channel updates may break unexpectedly
- No true "infrastructure as code" - git history doesn't capture full state

## Action Plan

**Priority: HIGH - Do this first as it affects everything else**

### 1. Enable flakes in configuration.nix

```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

### 2. Create `flake.nix` in dotfiles root

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager }: {
    nixosConfigurations.wiremind = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
      ];
    };
  };
}
```

### 3. Update `recrank.sh`

```bash
sudo nixos-rebuild switch --flake .#wiremind --verbose
```

### 4. Commit `flake.lock`

This is your reproducibility guarantee

## Sources

- [NixOS & Flakes Book - Getting Started with Home Manager](https://nixos-and-flakes.thiscute.world/nixos-with-flakes/start-using-home-manager)
- [Callista - Next step in Nix: Embracing Flakes and Home Manager](https://callistaenterprise.se/blogg/teknik/2025/04/10/nix-flakes/)
- [Determinate Systems - Nix flakes explained](https://determinate.systems/blog/nix-flakes-explained/)
- [Official NixOS Wiki - Flakes](https://wiki.nixos.org/wiki/Flakes)

## Estimated Effort

4-6 hours

## Implementation Order

Week 1: Security & Foundation
