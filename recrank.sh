#!/usr/bin/env bash
# Rebuild NixOS configuration using flakes
set -euo pipefail

export NIX_CONFIG="${NIX_CONFIG:-}
experimental-features = nix-command flakes"

nix_work_override=()
if [ -d ../nix-work ]; then
  nix_work_override=(--override-input nix-work "path:../nix-work")
fi

sudo nixos-rebuild switch --flake .#wiremind "${nix_work_override[@]}" --verbose
