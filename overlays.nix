{ self, ... } @ inputs:

let
	lib = inputs.nixpkgs.lib;
	
	pinnedPackages = {
		# not building on unstable: https://github.com/NixOS/nixpkgs/pull/403959
		nixpkgs-mealie = ["mealie"];
	};
in {
	pinnedPackages = final: prev: lib.concatMapAttrs (input: packages:
		builtins.listToAttrs (map (package: (
			lib.nameValuePair package inputs.${input}.legacyPackages.${final.system}.${package}
		)) packages)
	) pinnedPackages;
	
	utils = final: prev: let
		inherit (prev) callPackage;
	in {
		unindent = assert !(prev ? unindent); callPackage ./utils/unindent.nix {};
		wrapPackage = callPackage ./utils/wrap-package.nix {};
	};
	
	extraPackages = final: prev: let
		system = final.system;
	in {
		# make sure not to override existing packages, which others might depend on
		ndent = assert !(prev ? ndent); inputs.ndent.packages.${system}.ndent;
		journal = assert !(prev ? journal); inputs.journal.packages.${system}.journal;
		# TODO: remove if acmed is available on nixpkgs
		acmed = prev.callPackage ./packages/acmed.nix {};
		# TODO: remove if overlay works again
		solitaire = assert !(prev ? solitaire); prev.lib.makeScope prev.newScope (self: {
			cards = inputs.solitaire.packages.${system}.cards;
			native = inputs.solitaire.packages.${system}.native;
			web = inputs.solitaire.packages.${system}.web;
		});
		# TODO: remove if overlay works again
		vault-rs = assert !(prev ? vault-rs); inputs.vault.packages.${system}.default;
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
			
			jujutsu = callPackage ./packages/jujutsu.nix {};
		};
	};
	
	packages = final: prev: {
		owntracks-recorder = prev.callPackage ./packages/owntracks-recorder.nix {};
		owntracks-frontend = prev.callPackage ./packages/owntracks-frontend.nix {};
	};
	
	default = inputs.nixpkgs.lib.composeManyExtensions [
		self.overlays.pinnedPackages
		inputs.agenix.overlays.default
		inputs.nix-minecraft.overlays.default
		# TODO: enable if it works again
		# inputs.vault.overlays.default
		# TODO: enable if it works again
		# inputs.solitaire.overlays.default
		inputs.backy.overlays.default
		self.overlays.utils
		self.overlays.extraPackages
		self.overlays.configuredPackages
		self.overlays.packages
	];
}
