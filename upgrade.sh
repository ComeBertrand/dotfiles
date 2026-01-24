#!/usr/bin/env bash
# Update flake inputs (nixpkgs, home-manager, etc.) and rebuild
set -euo pipefail

export NIX_CONFIG="${NIX_CONFIG:-}
experimental-features = nix-command flakes"

nix_work_override=()
if [ -d ../nix-work ]; then
  nix_work_override=(--override-input nix-work "path:../nix-work")
fi

nix flake update
sudo nixos-rebuild switch --flake .#wiremind "${nix_work_override[@]}" --verbose
