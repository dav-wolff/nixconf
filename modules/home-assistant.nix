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
		};
		
		services.authing.settings = {
			groups = ["home-assistant"];
			hosts.homeAssistant = {
				host = config.modules.webServer.hosts.homeAssistant.domain;
				allow_group = "home-assistant";
			};
		};
		
		services.home-assistant = {
			enable = true;
			openFirewall = false;
			openFirewallForComponents = false;
			extraComponents = [
				"met"
				"my"
				"hue"
			];
			config = {
				http = {
					server_port = ports.homeAssistant;
					use_x_forwarded_for = true;
					trusted_proxies = "127.0.0.1";
				};
			};
		};
	};
}
