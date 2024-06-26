{ config, ... }:

{
	age.secrets.vaultwardenKey.file = ../secrets/vaultwardenKey.age;
	
	services.vaultwarden = {
		enable = true;
		backupDir = "/var/backup/vaultwarden";
		config = {
			ROCKET_PORT = 8222;
			DOMAIN = "https://bitwarden.dav.dev";
			PUSH_ENABLED = true;
			PUSH_RELAY_URI = "https://api.bitwarden.eu";
			PUSH_IDENTITY_URI = "https://identity.bitwarden.eu";
		};
		environmentFile = config.age.secrets.vaultwardenKey.path; # PUSH_INSTALLATION_ID and PUSH_INSTALLATION_KEY
	};
}
