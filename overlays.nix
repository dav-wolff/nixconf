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
	
	owntracks = final: prev: {
		owntracks-recorder = prev.callPackage ./packages/owntracks-recorder.nix {};
		owntracks-frontend = prev.callPackage ./packages/owntracks-frontend.nix {};
	};
	
	# TODO remove once immich gets merged
	immich = final: prev: {
		immich = let
			immich = inputs.nixpkgs-immich.legacyPackages.${final.system}.immich;
			args = builtins.intersectAttrs (prev.lib.functionArgs immich.override) final;
		in immich.override args;
	};
	
	immichVersion = final: prev: {
		immich = prev.immich.override {
			sources = rec {
				version = "1.115.0";
				src = prev.fetchFromGitHub {
					owner = "immich-app";
					repo = "immich";
					rev = "v${version}";
					hash = "sha256-H2FCR55redomrDjnnCQys47AaYbWEmlxO5NJEcVMBwY=";
				};
				npmDepsHashes = {
					server = "sha256-6CehRhPepspDpQW1h0Bx7EpH7hn42Ygqma/6wim14jA=";
					openapi = "sha256-l1mLYFpFQjYxytY0ZWLq+ldUhZA6so0HqPgCABt0s9k=";
					cli = "sha256-+zKtPHXjBd1KAKvI5xaY2/9qzVUg+8Ho/wrV9+TlU64=";
					web = "sha256-ZmXfYktgOmMkDjfqSGyyflr2CmnC9yVnJ1gAcmd6A00=";
				};
			};
		};
	};
	
	default = final: prev: prev.lib.composeManyExtensions [
		inputs.agenix.overlays.default
		inputs.vault.overlays.default
		inputs.solitaire.overlays.default
		inputs.backy.overlays.default
		self.overlays.extraPackages
		self.overlays.configuredPackages
		self.overlays.owntracks
		self.overlays.immich
		self.overlays.immichVersion
	] final prev;
}
