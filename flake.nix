{
	inputs.nixpkgs.url = "github:NixOS/nixpkgs";
	
	inputs.home-manager = {
		url = "github:nix-community/home-manager";
		inputs.nixpkgs.follows = "nixpkgs";
	};
	
	outputs = { self, nixpkgs, home-manager } @ args: {
		nixosConfigurations.max = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			modules = [
				./configuration.nix
				./nvidia.nix
				./max-hardware.nix
			];
			specialArgs = args // {
				name = "max";
			};
		};
	};
}