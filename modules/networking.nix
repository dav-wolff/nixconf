{ config, lib, ... }:

let
	cfg = config.modules.networking;
in {
	options.modules.networking.enable = lib.mkEnableOption "networking";
	
	config = lib.mkIf cfg.enable {
		networking.networkmanager.enable = true;
	};
}
