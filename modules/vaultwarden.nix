{ config, lib, ... }:

let
	cfg = config.modules.vaultwarden;
	inherit (config) ports;
in {
	options.modules.vaultwarden =  {
		enable = lib.mkEnableOption "vaultwarden";
	};
	
	config = lib.mkIf cfg.enable {
		modules.webServer.bitwarden = {
			enable = true;
			subdomain = "bitwarden";
			port = ports.vaultwarden;
		};
		
		age.secrets.vaultwardenKey.file = ../secrets/vaultwardenKey.age;
		
		services.vaultwarden = {
			enable = true;
			backupDir = "/var/backup/vaultwarden";
			config = {
				ROCKET_PORT = ports.vaultwarden;
				DOMAIN = "https://${config.modules.webServer.bitwarden.domain}";
				PUSH_ENABLED = true;
				PUSH_RELAY_URI = "https://api.bitwarden.eu";
				PUSH_IDENTITY_URI = "https://identity.bitwarden.eu";
			};
			environmentFile = config.age.secrets.vaultwardenKey.path; # PUSH_INSTALLATION_ID and PUSH_INSTALLATION_KEY
		};
	};
}
