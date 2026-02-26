{ config, lib, pkgs, ... }:

let
	cfg = config.modules.yamtrack;
in {
	options.modules.yamtrack.enable = lib.mkEnableOption "yamtrack";
	
	config = lib.mkIf cfg.enable {
		modules.webServer.hosts.yamtrack = {
			subdomain = "track";
			proxyPort = 8001;
			headers.content-security-policy = "frame-ancestors 'self'; default-src 'self' 'unsafe-inline' 'wasm-unsafe-eval' 'unsafe-eval' data: blob:; img-src 'self' data: blob: www.themoviedb.org image.tmdb.org images.igdb.com cdn.myanimelist.net assets.hardcover.app comicvine.gamespot.com cf.geekdo-images.com";
			locations."/static/" = {
				extraConfig = ''
					alias ${pkgs.yamtrack.staticfiles}/;
				'';
			};
		};
		
		age.secrets = {
			yamtrackSecrets = {
				# TMDB_API
				file = ../secrets/yamtrackSecrets.age;
			};
		};
		
		users.users.yamtrack = {
			group = "yamtrack";
			isSystemUser = true;
		};
		
		users.groups.yamtrack = {};
		
		services.redis.servers.yamtrack = {
			enable = true;
		};
		
		systemd.services.yamtrack = {
			description = "Yamtrack";
			wantedBy = ["multi-user.target"];
			
			environment = {
				TMDB_NSFW = "True";
				IGDB_NSFW = "True";
				DB_FILE = "/var/lib/yamtrack/db.sqlite3";
				REDIS_URL = "unix://${config.services.redis.servers.yamtrack.unixSocket}";
				CELERY_REDIS_URL = "redis+socket://${config.services.redis.servers.yamtrack.unixSocket}";
			};
			
			serviceConfig = {
				ExecStart = lib.getExe pkgs.yamtrack;
				EnvironmentFile = config.age.secrets.yamtrackSecrets.path;
				User = "yamtrack";
				Group = "yamtrack";
				SupplementaryGroups = config.services.redis.servers.yamtrack.group;
				StateDirectory = "yamtrack";
				StateDirectoryMode = "0700";
			};
		};
	};
}
