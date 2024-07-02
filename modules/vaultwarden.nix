{ config, lib, ... }:

let
	cfg = config.modules.vaultwarden;
in {
	options.modules.vaultwarden =  {
		enable = lib.mkEnableOption "vaultwarden";
		port = lib.mkOption {
			type = lib.types.port;
		};
	};
	
	config = lib.mkIf cfg.enable {
		modules.webServer.bitwarden = {
			enable = true;
			subdomain = "bitwarden";
			port = cfg.port;
		};
		
		age.secrets.vaultwardenKey.file = ../secrets/vaultwardenKey.age;
		
		services.vaultwarden = {
			enable = true;
			backupDir = "/var/backup/vaultwarden";
			config = {
				ROCKET_PORT = cfg.port;
				DOMAIN = "https://bitwarden.dav.dev";
				PUSH_ENABLED = true;
				PUSH_RELAY_URI = "https://api.bitwarden.eu";
				PUSH_IDENTITY_URI = "https://identity.bitwarden.eu";
			};
			environmentFile = config.age.secrets.vaultwardenKey.path; # PUSH_INSTALLATION_ID and PUSH_INSTALLATION_KEY
		};
	};
}
