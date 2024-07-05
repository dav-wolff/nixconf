{
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
	};
	
	outputs = { self, nixpkgs, flake-utils, ... } @ inputs: {
		nixosConfigurations = let
			nixosSystem = hostName: module: nixpkgs.lib.nixosSystem {
				system = null;
				modules = [
					self.nixosModules.default
					{
						networking.hostName = hostName;
					}
					./modules/hardware/${hostName}.nix
					module
				];
			};
		in {
			max = nixosSystem "max" {
				modules = {
					bootLoader.enable = true;
					networking.enable = true;
					desktop.enable = true;
					nvidia.enable = true;
				};
			};
			
			top = nixosSystem "top" {
				modules = {
					bootLoader.enable = true;
					networking.enable = true;
					desktop.enable = true;
				};
			};
			
			sub = nixosSystem "sub" {
				modules = {
					wsl.enable = true;
				};
			};
			
			shuttle = nixosSystem "shuttle" {
				imports = [
					inputs.nixos-hardware.nixosModules.common-gpu-nvidia-disable
				];
				
				modules = {
					bootLoader = {
						enable = true;
						useGrub = true;
					};
					
					networking.enable = true;
					sshServer.enable = true;
					hotspot.enable = true;
					
					webServer = {
						enable = true;
						domain = "dav.dev";
					};
					
					vault = {
						enable = true;
						port = 3103;
					};
					
					vaultwarden = {
						enable = true;
						port = 8222;
					};
				};
			};
		};
		
		overlays = {
			extraPackages = final: prev: let
				system = final.system;
			in {
				helix = inputs.helix.packages.${system}.helix;
				# make sure not to override existing packages, which others might depend on
				web-vault = assert !(prev ? web-vault); inputs.vault.packages.${system}.default;
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
			
			default = final: prev: prev.lib.composeManyExtensions [
				inputs.agenix.overlays.default
				self.overlays.extraPackages
				self.overlays.configuredPackages
			] final prev;
		};
		
		nixosModules.default = {
			imports = [
				inputs.agenix.nixosModules.default
				inputs.nixos-wsl.nixosModules.default
			] ++ import ./modules/all-modules.nix;
			nixpkgs.overlays = [self.overlays.default];
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
