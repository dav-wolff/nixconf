{ config, lib, pkgs, ... }:

let
	cfg = config.modules.fonts;
in {
	options.modules.fonts.enable = lib.mkEnableOption "fonts";
	
	config = lib.mkIf cfg.enable {
		fonts.packages = let
			nerdfonts = pkgs.nerdfonts.override {
				fonts = ["JetBrainsMono"];
			};
		in [
			nerdfonts
		];
	};
}
