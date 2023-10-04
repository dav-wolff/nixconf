{
	inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
	
	inputs.home-manager = {
		url = "github:nix-community/home-manager";
		inputs.nixpkgs.follows = "nixpkgs";
	};
	
	outputs = { self, nixpkgs, home-manager } @ args: {
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
