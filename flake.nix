{
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		
		flake-utils = {
			url = "github:numtide/flake-utils";
		};
		
		helix = {
			url = "github:helix-editor/helix";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		
		ndent = {
			url = "github:dav-wolff/ndent";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		
		journal = {
			url = "github:dav-wolff/journal";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};
	
	outputs = { self, nixpkgs, flake-utils, helix, ... } @ args: {
		nixosConfigurations = {
			max = nixpkgs.lib.nixosSystem {
				system = "x86_64-linux";
				modules = [
					./configuration.nix
					./modules/boot-loader.nix
					./modules/networking.nix
					./modules/desktop.nix
					./modules/nvidia.nix
					./modules/max-hardware.nix
				];
				specialArgs = args // {
					name = "max";
				};
			};
			
			top = nixpkgs.lib.nixosSystem {
				system = "x86_64-linux";
				modules = [
					./configuration.nix
					./modules/boot-loader.nix
					./modules/networking.nix
					./modules/desktop.nix
					./modules/top-hardware.nix
				];
				specialArgs = args // {
					name = "top";
				};
			};
			
			sub = nixpkgs.lib.nixosSystem {
				system = "x86_64-linux";
				modules = [
					./configuration.nix
					./modules/wsl.nix
				];
				specialArgs = args // {
					name = "sub";
				};
			};
		};
	} // flake-utils.lib.eachDefaultSystem (system: let
		pkgs = import nixpkgs {
			inherit system;
		};
	in {
		packages = {
			helix = import ./packages/helix.nix {
				inherit pkgs;
				helix = helix.packages.${system}.helix;
			};
			
			zellij = import ./packages/zellij.nix {
				inherit pkgs;
			};
		};
	});
}
