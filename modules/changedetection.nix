{ config, lib, pkgs, ... }:

let
	cfg = config.modules.changedetection;
	inherit (config) ports;
in {
	options.modules.changedetection.enable = lib.mkEnableOption "changedetection";
	
	config = lib.mkIf cfg.enable {
		modules.webServer.hosts.changedetection = {
			subdomain = "change";
			proxyPort = ports.changedetection;
		};
		
		# TODO add options for this in webServer hosts
		# service is single user, so don't allow everyone to log in
		services.authelia.instances.main = {
			settings.access_control.rules = [
				{
					domain = config.modules.webServer.hosts.changedetection.domain;
					policy = "one_factor";
					subject = "user:dav";
				}
				{
					domain = config.modules.webServer.hosts.changedetection.domain;
					policy = "deny";
				}
			];
		};
		
		services.changedetection-io = {
			enable = true;
			behindProxy = true;
			port = ports.changedetection;
			baseURL = config.modules.webServer.hosts.changedetection.domain;
			environmentFile = pkgs.writeText "changedetection-io.env" ''
				HIDE_REFERER=false
			'';
		};
	};
}
