{ lib, config, ... }:

let
	cfg = config.modules.nextcloud;
in {
	options.modules.nextcloud = {
		enable = lib.mkEnableOption "nextcloud";
		adminPassword = lib.mkOption {
			type = lib.types.pathInStore;
		};
		volume = lib.mkOption {
			type = lib.types.str;
		};
	};
	
	config = lib.mkIf cfg.enable {
		age.secrets.nextcloudAdminPassword = {
			file = cfg.adminPassword;
			owner = "nextcloud";
		};
		
		modules.webServer.nextcloud = {
			enable = true;
			subdomain = "nextcloud";
		};
		
		services.nextcloud = {
			enable = true;
			https = true;
			home = cfg.volume;
			config.adminpassFile = config.age.secrets.nextcloudAdminPassword.path;
		};
	};
}
