{ config, lib, ... }:

let
	cfg = config.modules.homeAssistant;
	inherit (config) ports;
in {
	options.modules.homeAssistant.enable = lib.mkEnableOption "homeAssistant";
	
	config = lib.mkIf cfg.enable {
		modules.webServer.hosts.homeAssistant = {
			subdomain = "ha";
			proxyPort = ports.homeAssistant;
			authing.allow_group = "home-assistant";
		};
		
		services.home-assistant = {
			enable = true;
			openFirewallForComponents = false;
			extraComponents = [
				"met"
				"my"
				"hue"
			];
			config = {
				"automation ui" = "!include automations.yaml";
				"scene ui" = "!include scenes.yaml";
				http = {
					server_port = ports.homeAssistant;
					use_x_forwarded_for = true;
					trusted_proxies = "127.0.0.1";
				};
			};
		};
	};
}
