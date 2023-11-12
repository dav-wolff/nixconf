{
	inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
	
	inputs.home-manager = {
		url = "github:nix-community/home-manager";
		inputs.nixpkgs.follows = "nixpkgs";
	};
	
	inputs.ndent = {
		url = "github:dav-wolff/ndent";
		inputs.nixpkgs.follows = "nixpkgs";
	};
	
	inputs.journal = {
		url = "github:dav-wolff/journal";
		inputs.nixpkgs.follows = "nixpkgs";
	};
	
	outputs = { self, nixpkgs, ... } @ args: {
		nixosConfigurations.max = nixpkgs.lib.nixosSystem {
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
		
		nixosConfigurations.sub = nixpkgs.lib.nixosSystem {
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
}
