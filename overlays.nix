{ self, ... } @ inputs:

let
	lib = inputs.nixpkgs.lib;
	
	# nixpkgs-pinned = [pinned-packages];
	pinnedPackages = {
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
		acmed = prev.callPackage ./packages/acmed.nix {
			acceptLetsencryptTerms = true;
		};
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
				shell = final.configured.zsh;
			};
			
			jujutsu = callPackage ./packages/jujutsu.nix {};
		};
	};
	
	packages = final: prev: {
		owntracks-recorder = prev.callPackage ./packages/owntracks-recorder.nix {};
		owntracks-frontend = prev.callPackage ./packages/owntracks-frontend.nix {};
	};
	
	overrides = final: prev: {
		lldap = let
			inherit (final) fetchurl;
			
			# https://github.com/lldap/lldap/blob/main/app/static/libraries.txt
			bootstrap-nightshade = fetchurl {
				url = "https://cdn.jsdelivr.net/npm/bootstrap-dark-5@1.1.3/dist/css/bootstrap-nightshade.min.css";
				hash = "sha256-o4/KvOMbqkanQIhEKRG5j11aFGYHpgfB8Zy8mInEzSU=";
			};
			darkmode = fetchurl {
				url = "https://cdn.jsdelivr.net/npm/bootstrap-dark-5@1.1.3/dist/js/darkmode.min.js";
				hash = "sha256-TJFCDUJIlHldAZoOahUGxmotcxJRiV2ZwL2ztw/0sZY=";
			};
			bootstrap = fetchurl {
				url = "https://cdn.jsdelivr.net/npm/bootstrap@5.1.1/dist/js/bootstrap.bundle.min.js";
				hash = "sha256-5aErhPlUPVujIxg3wvJGdWNAWqZqWCtvxACYX4XfSa0=";
			};
			bootstrap-icons = fetchurl {
				url = "https://cdn.jsdelivr.net/npm/bootstrap-icons@1.5.0/font/bootstrap-icons.css";
				hash = "sha256-PDJQdTN7dolQWDASIoBVrjkuOEaI137FI15sqI3Oxu8=";
			};
			font-awesome = fetchurl {
				url = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css";
				hash = "sha256-eZrrJcwDc/3uDhsdt61sL2oOBY362qM3lon1gyExkL0=";
			};
			
			# https://github.com/lldap/lldap/blob/main/app/static/fonts/fonts.txt
			# bootstrap-icons.woff2 doesn't seem to be used
			bootstrap-icons-font = fetchurl {
				url = "https://cdn.jsdelivr.net/npm/bootstrap-icons@1.5.0/font/fonts/bootstrap-icons.woff2";
				hash = "sha256-dlBuEo8rR7cXn1A3vYhaFnRFX/62tQk820x+779DbOg=";
			};
			bebasNeue1 = fetchurl {
				url = "https://fonts.gstatic.com/s/bebasneue/v2/JTUSjIg69CK48gW7PXoo9Wdhyzbi.woff2";
				hash = "sha256-WL2vM0gNANjH7sGw7jLp+T8m7PsF3vdVEES8j1zQ4vM=";
			};
			bebasNeue2 = fetchurl {
				url = "https://fonts.gstatic.com/s/bebasneue/v2/JTUSjIg69CK48gW7PXoo9Wlhyw.woff2";
				hash = "sha256-2rcpDryQt+0waLKSG/UeAmIlrUjns5ixIyHQNtNApFg=";
			};
			
			frontend = prev.lldap.frontend.overrideAttrs (finalAttrs: prevAttrs: {
				installPhase = ''
					runHook preInstall
					${prevAttrs.installPhase}
					runHook postInstall
				'';
				
				postInstall = ''
					cp app/index_local.html $out/index.html
					cp ${bootstrap-nightshade} $out/static/bootstrap-nightshade.min.css
					cp ${darkmode} $out/static/darkmode.min.js
					cp ${bootstrap} $out/static/bootstrap.bundle.min.js
					cp ${bootstrap-icons} $out/static/bootstrap-icons.css
					cp ${font-awesome} $out/static/font-awesome.min.css
					
					cp ${bootstrap-icons-font} $out/static/fonts/bootstrap-icons.woff2
					cp ${bebasNeue1} $out/static/fonts/JTUSjIg69CK48gW7PXoo9Wdhyzbi.woff2
					cp ${bebasNeue2} $out/static/fonts/JTUSjIg69CK48gW7PXoo9Wlhyw.woff2
				'';
			});
		in prev.lldap.overrideAttrs (finalAttrs: prevAttrs: {
			postInstall = ''
				wrapProgram $out/bin/lldap \
					--set LLDAP_ASSETS_PATH ${finalAttrs.passthru.frontend}
			'';
			passthru.frontend = frontend;
		});
	};
	
	default = inputs.nixpkgs.lib.composeManyExtensions [
		self.overlays.pinnedPackages
		inputs.agenix.overlays.default
		inputs.nix-minecraft.overlays.default
		# TODO: enable if it works again
		# inputs.vault.overlays.default
		# TODO: enable if it works again
		# inputs.solitaire.overlays.default
		inputs.simplewall.overlays.default
		inputs.backy.overlays.default
		inputs.linky.overlays.default
		self.overlays.utils
		self.overlays.extraPackages
		self.overlays.configuredPackages
		self.overlays.packages
		self.overlays.overrides
	];
}
