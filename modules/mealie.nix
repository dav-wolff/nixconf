{ lib, config, ... }:

let
	cfg = config.modules.mealie;
	inherit (config) ports;
in {
	options.modules.mealie.enable = lib.mkEnableOption "mealie";
	
	config = lib.mkIf cfg.enable {
		modules.webServer.hosts.mealie = {
			proxyPort = ports.mealie;
		};
		
		age.secrets.mealieOidcSecret = {
			file = ../secrets/mealieOidcSecret.age;
		};
		
		services.mealie = {
			enable = true;
			port = ports.mealie;
			settings = {
				BASE_URL = "https://${config.modules.webServer.hosts.mealie.domain}";
				OIDC_AUTH_ENABLED = true;
				OIDC_SIGNUP_ENABLE = true;
				OIDC_AUTO_REDIRECT = true;
				OIDC_CLIENT_ID = "mealie";
				OIDC_CONFIGURATION_URL = "https://${config.modules.webServer.auth.domain}/.well-known/openid-configuration";
			};
			credentialsFile = config.age.secrets.mealieOidcSecret.path;
		};
		
		services.authelia.instances.main = {
			settings.identity_providers.oidc.clients = [
				{
					client_id = "mealie";
					client_name = "Mealie";
					client_secret = "$argon2id$v=19$m=65536,t=3,p=4$ah2caPRONZWMql7PQpy7pA$i+xYNr42GQ3EoYmmP80JIkASkqBZ72u3hhanCgv8RRM";
					authorization_policy = "one_factor";
					require_pkce = true;
					pkce_challenge_method = "S256";
					redirect_uris = [
						"https://${config.modules.webServer.hosts.mealie.domain}/login"
					];
					scopes = [
						"openid"
						"email"
						"profile"
						"groups"
					];
					
				}
			];
		};
	};
}
