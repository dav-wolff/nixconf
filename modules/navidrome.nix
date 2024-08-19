{ config, lib, ... }:

let
	cfg = config.modules.navidrome;
in {
	options.modules.navidrome = {
		enable = lib.mkEnableOption "navidrome";
		volume = lib.mkOption {
			type = lib.types.str;
		};
		port = lib.mkOption {
			type = lib.types.port;
		};
		passwordFile = lib.mkOption {
			type = lib.types.pathInStore;
		};
	};
	
	config = lib.mkIf cfg.enable {
		age.secrets.navidromePassword = {
			file = cfg.passwordFile;
			owner = "nginx";
		};
		
		modules.webServer.navidrome = {
			enable = true;
			subdomain = "music";
			port = cfg.port;
			passwordFile = config.age.secrets.navidromePassword.path;
		};
		
		services.navidrome = {
			enable = true;
			settings = {
				Port = cfg.port;
				MusicFolder = "${cfg.volume}/music";
				DataFolder = "${cfg.volume}/data";
				CacheFolder = "${cfg.volume}/cache";
			};
		};
	};
}
