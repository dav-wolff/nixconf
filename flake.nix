{
	description = "dav's NixOS configurations";
	
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		flake-utils.url = "github:numtide/flake-utils";
		agenix.url = "github:ryantm/agenix";
		nixos-hardware.url = "github:NixOS/nixos-hardware";
		nix-minecraft.url = "github:Infinidoge/nix-minecraft";
		wrappers = {
			url = "github:Lassulus/wrappers";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		nixos-wsl = {
			url = "github:nix-community/NixOS-WSL";
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
		linky = {
			url = "github:dav-wolff/linky";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		vault = {
			url = "github:dav-wolff/vault";
		};
		solitaire = {
			url = "github:dav-wolff/solitaire";
		};
		simplewall.url = "github:dav-wolff/simplewall";
		authing = {
			url = "git+ssh://git@git.dav.dev/dav/authing.git";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		immich = {
			url = "github:immich-app/immich/0b3633db4f2c6b050475554387e63be03bdf9a6d";
			flake = false;
		};
		nixpkgs-immich.url = "github:dav-wolff/nixpkgs/immich-overridable";
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
		
		nixosModules.default = { lib, ... }: let
			modules = lib.filter (lib.strings.hasSuffix ".nix") (lib.filesystem.listFilesRecursive ./modules);
		in {
			imports = [
				inputs.agenix.nixosModules.default
				inputs.nixos-wsl.nixosModules.default
				inputs.nix-minecraft.nixosModules.minecraft-servers
				inputs.authing.nixosModules.default
			] ++ modules;
			nixpkgs.overlays = [self.overlays.default];
			modules.nix.pkgs = self;
			system.stateVersion = "24.05";
		};
	} // flake-utils.lib.eachDefaultSystem (system: let
		pkgs = import nixpkgs {
			inherit system;
			overlays = [
				self.overlays.default
			];
		};
	in {
		packages = pkgs.configured;
		
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
