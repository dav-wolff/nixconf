{ config, lib, pkgs, ... }:

let
	cfg = config.modules.immich;
in {
	options.modules.immich = {
		enable = lib.mkEnableOption "immich";
		remoteMachineLearning = lib.mkOption {
			type = lib.types.bool;
			default = false;
		};
		volume = lib.mkOption {
			type = lib.types.str;
		};
		port = lib.mkOption {
			type = lib.types.port;
		};
	};
	
	config = lib.mkMerge [
		{
			environment.systemPackages = [pkgs.immich-cli];
		}
		(lib.mkIf cfg.enable {
			modules.webServer.immich = {
				enable = true;
				subdomain = "immich";
				port = cfg.port;
			};
			
			modules.email = {
				enable = true;
				senders = ["immich"];
			};
			
			services.immich = {
				enable = true;
				mediaLocation = cfg.volume;
				port = cfg.port;
				settings = {
					server = {
						externalDomain = "https://${config.modules.webServer.immich.domain}";
					};
					machineLearning.urls = [
						"http://max.local:8333" # TODO: https
						"http://localhost:3003"
					];
					user.deleteDelay = 30;
					notifications.smtp = {
						enabled = true;
						from = "Immich <immich@${config.modules.email.domain}>";
						transport = {
							host = "localhost";
							port = 4323;
						};
					};
				};
			};
			
			modules.immich.remoteMachineLearning = false;
		})
		(lib.mkIf cfg.remoteMachineLearning {
			modules.firewall.localAllowedTCPPorts = [cfg.port];
			
			services.immich = {
				enable = true;
				database.enable = false;
				redis.enable = false;
				machine-learning.environment = {
					IMMICH_HOST = lib.mkForce "0.0.0.0";
					IMMICH_PORT = lib.mkForce (toString cfg.port);
				};
			};
			
			systemd.services.immich-server = lib.mkForce {};
		})
	];
}
