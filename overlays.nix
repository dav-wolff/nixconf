{ self, ... } @ inputs:

{
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
	
	packages = final: prev: {
		owntracks-recorder = prev.callPackage ./packages/owntracks-recorder.nix {};
		owntracks-frontend = prev.callPackage ./packages/owntracks-frontend.nix {};
	};
	
	# TODO: remove once bitwarden builds on unstable again
	fixBitwarden = final: prev: {
		bitwarden-desktop = inputs.nixpkgs-bitwarden.legacyPackages.${final.system}.bitwarden-desktop;
	};
	
	default = inputs.nixpkgs.lib.composeManyExtensions [
		inputs.agenix.overlays.default
		inputs.nix-minecraft.overlays.default
		inputs.vault.overlays.default
		inputs.solitaire.overlays.default
		inputs.backy.overlays.default
		self.overlays.extraPackages
		self.overlays.configuredPackages
		self.overlays.packages
		# TODO: remove once bitwarden builds on unstable again
		self.overlays.fixBitwarden
	];
}
