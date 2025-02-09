{ config, lib, pkgs, ... }:

let
	cfg = config.modules.changedetection;
	inherit (config) ports;
in {
	options.modules.changedetection = {
		enable = lib.mkEnableOption "changedetection";
		passwordFile = lib.mkOption {
			type = lib.types.pathInStore;
		};
	};
	
	config = lib.mkIf cfg.enable {
		age.secrets.changedetectionPassword = {
			file = cfg.passwordFile;
			owner = "nginx";
		};
		
		modules.webServer.changedetection = {
			enable = true;
			subdomain = "changedetection";
			port = ports.changedetection;
			passwordFile = config.age.secrets.changedetectionPassword.path;
		};
		
		services.changedetection-io = {
			enable = true;
			behindProxy = true;
			port = ports.changedetection;
			baseURL = config.modules.webServer.changedetection.domain;
			environmentFile = pkgs.writeText "changedetection-io.env" ''
				HIDE_REFERER=false
			'';
		};
	};
}
