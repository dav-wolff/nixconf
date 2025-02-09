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
			port = ports.navidrome;
			passwordFile = config.age.secrets.navidromePassword.path;
		};
		
		services.navidrome = {
			enable = true;
			settings = {
				Port = ports.navidrome;
				MusicFolder = "${cfg.volume}/music";
				DataFolder = "${cfg.volume}/data";
				CacheFolder = "${cfg.volume}/cache";
			};
		};
	};
}
