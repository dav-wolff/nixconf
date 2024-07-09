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
		
		solitaire = {
			url = "github:dav-wolff/solitaire";
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
						solitaire = {
							enable = true;
							subdomain = "solitaire";
						};
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
				self.overlays.fixFirefox
			] final prev;
		};
		
		nixosModules.default = {
			imports = [
				inputs.agenix.nixosModules.default
				inputs.nixos-wsl.nixosModules.default
			] ++ import ./modules/all-modules.nix;
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
