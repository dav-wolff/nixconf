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
			
			locations."= /auth/login" = {
				# return 200 so clients don't think that login faile
				# add dummy data so clients don't fail parsing the response
				# https://github.com/navidrome/navidrome/blob/cc3cca607749dc086480f1af078fbbeb3fac2bdb/server/auth.go#L66-L95
				headers.content-type = "application/json";
				staticText = builtins.toJSON {
					id = "-";
					name = "-";
					username = "-";
					isAdmin = false;
					subsonicSalt = "-";
					subsonicToken = "-";
					token = "-";
				};
			};
		};
		
		services.authing.settings.share_links.navidrome = {
			match_host = config.modules.webServer.hosts.navidrome.domain;
			match_paths = ["/share/"];
			redirect = "http://127.0.0.1:${toString ports.navidrome}";
		};
		
		services.navidrome = {
			enable = true;
			settings = {
				Port = ports.navidrome;
				MusicFolder = "${cfg.volume}/music";
				DataFolder = "${cfg.volume}/data";
				CacheFolder = "${cfg.volume}/cache";
				ReverseProxyWhitelist = "127.0.0.1/32";
				BaseUrl = "https://${config.modules.webServer.hosts.navidrome.domain}";
				EnableSharing = true;
				EnableUserEditing = false;
				AutoImportPlaylists = false;
				DefaultTheme = "Nord";
				Inspect.Enabled = false;
				Scanner.PurgeMissing = "always";
			};
		};
	};
}
