{ config, lib, ... }:

let
	cfg = config.modules.navidrome;
	inherit (config) ports;
in {
	options.modules.navidrome = {
		enable = lib.mkEnableOption "navidrome";
		volume = lib.mkOption {
			type = lib.types.str;
		};
	};
	
	config = lib.mkIf cfg.enable {
		modules.webServer.hosts.navidrome = {
			subdomain = "music";
			proxyPort = ports.navidrome;
		};
		
		services.navidrome = {
			enable = true;
			settings = {
				Port = ports.navidrome;
				MusicFolder = "${cfg.volume}/music";
				DataFolder = "${cfg.volume}/data";
				CacheFolder = "${cfg.volume}/cache";
				ReverseProxyWhitelist = "127.0.0.1/32";
			};
		};
	};
}
