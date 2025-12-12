{ config, lib, ... }:

let
	cfg = config.modules.networking;
in {
	options.modules.networking = {
		enable = lib.mkEnableOption "networking";
		useNetworkd = lib.mkOption {
			type = lib.types.bool;
			default = false;
		};
	};
	
	config = lib.mkIf cfg.enable {
		# use networkmanager for desktop and systemd-networkd for servers
		networking.networkmanager.enable = !cfg.useNetworkd;
		
		# TODO: this isn't even enabled on min? how does min work?
		systemd.network.enable = cfg.useNetworkd;
		networking.useNetworkd = cfg.useNetworkd;
		
		# local dns resolution
		services.avahi = {
			enable = true;
			nssmdns4 = true;
		};
	};
}
