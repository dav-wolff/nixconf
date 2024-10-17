{
	description = "dav's NixOS configurations";
	
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		
		# TODO: remove once bitwarden builds on unstable again
		nixpkgs-bitwarden.url = "github:NixOS/nixpkgs/a2cad4db0b6d352c0bc484f82e48c445f8092778";
		
		flake-utils = {
			url = "github:numtide/flake-utils";
		};
		
		agenix = {
			url = "github:ryantm/agenix";
		};
		
		nixos-hardware = {
			url = "github:NixOS/nixos-hardware";
		};
		
		nixos-wsl = {
			url = "github:nix-community/NixOS-WSL";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		
		helix = {
			url = "github:helix-editor/helix";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		
		backy = {
			url = "github:dav-wolff/backy";
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
		
		vault = {
			url = "github:dav-wolff/vault";
		};
		
		solitaire = {
			url = "github:dav-wolff/solitaire";
		};
	};
	
	outputs = { self, nixpkgs, flake-utils, ... } @ inputs: {
		nixosConfigurations = let
			lib = nixpkgs.lib;
			
			pathToName = path: let
				baseName = builtins.baseNameOf path;
				length = builtins.stringLength baseName;
			in builtins.substring 0 (length - 4) baseName;
			
			pathToSystem = path: let
				hostName = pathToName path;
				config = import path;
				module = if builtins.isFunction config then
					config inputs
				else
					config;
			in lib.nixosSystem {
				system = null;
				modules = [
					self.nixosModules.default
					{
						networking.hostName = hostName;
					}
					./hardware-modules/${hostName}.nix
					module
				];
			};
			
			systems = builtins.listToAttrs (map (path: {
				name = pathToName path;
				value = pathToSystem path;
			}) (lib.filesystem.listFilesRecursive ./systems));
		in systems;
		
		overlays = import ./overlays.nix inputs;
		
		nixosModules.default = { lib, ... }: {
			imports = [
				inputs.agenix.nixosModules.default
				inputs.nixos-wsl.nixosModules.default
				# TODO remove
				./configuration.nix
			] ++ lib.filesystem.listFilesRecursive ./modules;
			nixpkgs.overlays = [self.overlays.default];
			modules.nix.pkgs = self;
			modules.nix.nixpkgs = nixpkgs;
		};
	} // flake-utils.lib.eachDefaultSystem (system: let
		pkgs = import nixpkgs {
			inherit system;
			overlays = [
				self.overlays.default
			];
		};
	in {
		packages = {
			inherit (pkgs.configured) helix zsh zellij alacritty;
		};
		
		# Packages for use from flake registry
		legacyPackages = pkgs;
		
		apps = {
			update = {
				type = "app";
				program = "${import ./update.nix pkgs}/bin/update";
			};
		};
		
		devShells.default = pkgs.mkShell {
			packages = with pkgs; [
				helix
				zsh
				zellij
			];
			
			shellHook = ''
				zellij
				exit
			'';
		};
	});
}
