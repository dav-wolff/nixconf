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
