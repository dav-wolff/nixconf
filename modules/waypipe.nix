{ config, lib, pkgs, ... }:

let
	cfg = config.modules.waypipe;
in {
	options.modules.waypipe.enable = lib.mkEnableOption "waypipe";
	
	config = lib.mkIf cfg.enable {
		environment.systemPackages = [
			pkgs.waypipe
		];
		
		hardware.graphics.enable = true;
	};
}
