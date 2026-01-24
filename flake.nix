{
  description = "NixOS configuration with Nix Flakes for reproducible builds";

  inputs = {
    # NixOS 25.05 stable
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    # NixOS unstable for bleeding-edge packages
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager release-25.05
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Optional work-specific module (override with --override-input nix-work)
    nix-work = {
      url = "path:./nix-work";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, home-manager, ... }:
    let
      system = "x86_64-linux";

      # Unstable packages with allowUnfree
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };

      # Work-specific module (defaults to ./nix-work; override input for external)
      nixWorkPath =
        if builtins.isPath inputs."nix-work"
        then inputs."nix-work"
        else inputs."nix-work".outPath;
      nixWorkModule = nixWorkPath + "/default.nix";
    in
    {
      nixosConfigurations.wiremind = nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          inherit pkgs-unstable;
        };

        modules = [
          # Main configuration
          ./configuration.nix
          nixWorkModule

          # Home Manager module
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
        ];
      };
    };
}
