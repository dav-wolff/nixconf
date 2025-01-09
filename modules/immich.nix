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
			
			services.immich = {
				enable = true;
				mediaLocation = cfg.volume;
				port = cfg.port;
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
