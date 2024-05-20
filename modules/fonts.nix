{ pkgs, ... }:

{
	fonts.packages = let
		nerdfonts = pkgs.nerdfonts.override {
			fonts = ["JetBrainsMono"];
		};
	in [
		nerdfonts
	];
}
