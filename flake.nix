{
	description = "dav's NixOS configurations";
	
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		
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
			inputs.nixpkgs.follows = "nixpkgs";
		};
		
		solitaire = {
			url = "github:dav-wolff/solitaire";
			inputs.nixpkgs.follows = "nixpkgs";
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
		
		overlays = {
			extraPackages = final: prev: let
				system = final.system;
			in {
				helix = inputs.helix.packages.${system}.helix;
				# make sure not to override existing packages, which others might depend on
				ndent = assert !(prev ? ndent); inputs.ndent.packages.${system}.ndent;
				journal = assert !(prev ? journal); inputs.journal.packages.${system}.journal;
			};
			
			configuredPackages = final: prev: let
				inherit (prev) callPackage;
			in {
				configured = assert !(prev ? configured); {
					helix = callPackage ./packages/helix.nix {};
					
					zsh = callPackage ./packages/zsh.nix {};
					
					zellij = callPackage ./packages/zellij.nix {};
					
					alacritty = callPackage ./packages/alacritty.nix {
						shell = final.configured.zellij;
					};
				};
			};
			
			owntracks = final: prev: {
				owntracks-recorder = prev.callPackage ./packages/owntracks-recorder.nix {};
				owntracks-frontend = prev.callPackage ./packages/owntracks-frontend.nix {};
			};
			
			# temporary fix, firefox currently crashes when using wayland
			# https://bugzilla.mozilla.org/show_bug.cgi?id=1898476
			fixFirefox = final: prev: {
				wrapFirefox = browser: { applicationName ? browser.binaryName or (prev.lib.getName browser), ... } @ attrs: let
					wrapped-browser = prev.wrapFirefox browser attrs;
				in wrapped-browser.overrideAttrs (old: {
					buildCommand = ''
						${old.buildCommand}
						substituteInPlace $out/bin/${applicationName} --replace "exec -a" "MOZ_ENABLE_WAYLAND=0 exec -a"
					'';
				});
			};
			
			default = final: prev: prev.lib.composeManyExtensions [
				inputs.agenix.overlays.default
				inputs.vault.overlays.default
				inputs.solitaire.overlays.default
				self.overlays.extraPackages
				self.overlays.configuredPackages
				self.overlays.owntracks
				self.overlays.fixFirefox
			] final prev;
		};
		
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
