{ config, lib, pkgs, ... }:

let
	cfg = config.modules.fonts;
in {
	options.modules.fonts.enable = lib.mkEnableOption "fonts";
	
	config = lib.mkIf cfg.enable {
		fonts.packages = with pkgs; [
			nerd-fonts.jetbrains-mono
		];
	};
}
