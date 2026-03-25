{
  description = "NixOS configuration with Nix Flakes for reproducible builds";

  inputs = {
    # NixOS 25.11 stable
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    # NixOS unstable for bleeding-edge packages
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager release-25.11
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # LLM coding agents (claude-code, gemini-cli, codex, etc.)
    # Auto-updated daily with binary cache from Numtide
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
    };

    # Worktree navigator + project discovery
    yawn.url = "github:ComeBertrand/yawn";

    # Terminal multiplexer for AI coding agents
    zinc.url = "github:ComeBertrand/zinc";

    # Terminal multiplexer for AI coding agents
    tam.url = "github:ComeBertrand/tam";

    # Optional work-specific module (override with --override-input nix-work)
    nix-work = {
      url = "path:./nix-work";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, home-manager, llm-agents, yawn, zinc, tam, ... }:
    let
      system = "x86_64-linux";

      # Unstable packages with allowUnfree
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };

      # LLM agent packages from Numtide
      llmPkgs = llm-agents.packages.${system};

      # Yawn worktree navigator
      yawnPkg = yawn.packages.${system}.default;

      # Zinc agent multiplexer
      zincPkg = zinc.packages.${system}.default;

      # Tam agent multiplexer
      tamPkg = tam.packages.${system}.default;

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
          inherit pkgs-unstable llmPkgs yawnPkg zincPkg tamPkg;
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
