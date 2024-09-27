{ config, lib, pkgs, ... }:

let
	cfg = config.modules.immich;
in {
	options.modules.immich = {
		enable = lib.mkEnableOption "immich";
		volume = lib.mkOption {
			type = lib.types.str;
		};
		port = lib.mkOption {
			type = lib.types.port;
		};
	};
	
	config = lib.mkMerge [
		{
			# TODO: add it back
			# environment.systemPackages = [pkgs.immich-cli];
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
		})
	];
}
