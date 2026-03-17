{ config, lib, pkgs, ... }:

let
	cfg = config.modules.yamtrack;
	inherit (config) ports;
in {
	options.modules.yamtrack.enable = lib.mkEnableOption "yamtrack";
	
	config = lib.mkIf cfg.enable {
		modules.webServer.hosts.yamtrack = {
			subdomain = "track";
			proxyPort = ports.yamtrack;
			headers.content-security-policy = "frame-ancestors 'self'; default-src 'self' 'unsafe-inline' 'wasm-unsafe-eval' 'unsafe-eval' data: blob:; img-src 'self' data: blob: www.themoviedb.org image.tmdb.org images.igdb.com cdn.myanimelist.net assets.hardcover.app comicvine.gamespot.com cf.geekdo-images.com";
			locations."/static/" = {
				extraConfig = ''
					alias ${pkgs.yamtrack.staticFiles}/;
				'';
			};
		};
		
		age.secrets = {
			yamtrackSecrets = {
				# TMDB_API
				file = ../secrets/yamtrackSecrets.age;
			};
		};
		
		services.yamtrack = {
			enable = true;
			port = ports.yamtrack;
			virtualHost = null;
			environment = {
				TMDB_NSFW = "True";
				IGDB_NSFW = "True";
			};
		};
	};
}
