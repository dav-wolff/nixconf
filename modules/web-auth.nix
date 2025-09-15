{ config, lib, pkgs, ... }:

let
	cfg = config.modules.webServer;
	inherit (config) ports;
in {
	options.modules.webServer.auth = let
		inherit (lib) types;
	in {
		enable = lib.mkEnableOption "webServer.auth";
		baseDomain = lib.mkOption {
			type = types.str;
			default = cfg.baseDomain;
		};
		sessionName = lib.mkOption {
			type = types.str;
			default = "main";
		};
		enableOidc = lib.mkOption {
			type = types.bool;
			default = false;
		};
	};
	
	config = lib.mkIf cfg.enable {
		age.secrets = let
			owner = config.services.authelia.instances.main.user;
		in {
			autheliaJwtSecret = {
				inherit owner;
				file = ../secrets/autheliaJwtSecret.age;
			};
			autheliaStorageEncryptionKey = {
				inherit owner;
				file = ../secrets/autheliaStorageEncryptionKey.age;
			};
			autheliaOidcHmac = lib.mkIf cfg.auth.enableOidc {
				inherit owner;
				file = ../secrets/autheliaOidcHmac.age;
			};
			autheliaOidcPrivateKey = lib.mkIf cfg.auth.enableOidc {
				inherit owner;
				file = ../secrets/autheliaOidcPrivateKey.age;
			};
			lldapKeySeed = {
				file = ../secrets/lldapKeySeed.age;
				owner = "lldap";
			};
			lldapAdminPassword = {
				file = ../secrets/lldapAdminPassword.age;
				owner = "lldap";
			};
			lldapAutheliaPassword = {
				inherit owner;
				file = ../secrets/lldapAutheliaPassword.age;
			};
		};
		
		## Authelia
		
		modules.webServer.hosts.auth = {
			auth = false;
			headers.content-security-policy = null; # set by authelia
			locations = let
				location = {
					proxyPort = ports.authelia;
				};
			in {
				"/" = location;
				"= /api/verify" = location;
				"/api/authz/" = location;
			};
		};
		
		services.authelia.instances.main = {
			enable = true;
			secrets = {
				jwtSecretFile = config.age.secrets.autheliaJwtSecret.path;
				storageEncryptionKeyFile = config.age.secrets.autheliaStorageEncryptionKey.path;
				oidcHmacSecretFile = lib.mkIf cfg.auth.enableOidc config.age.secrets.autheliaOidcHmac.path;
				oidcIssuerPrivateKeyFile = lib.mkIf cfg.auth.enableOidc config.age.secrets.autheliaOidcPrivateKey.path;
			};
			settings = {
				theme = "dark";
				server = {
					address = "tcp://:${toString ports.authelia}/";
					endpoints.authz.auth-request.implementation = "AuthRequest";
				};
				authentication_backend = {
					refresh_interval = "1m";
					ldap = {
						implementation = "lldap";
						address = "ldap://localhost:${toString ports.lldap}";
						base_dn = config.services.lldap.settings.ldap_base_dn;
						# TODO: can this user be created automatically?
						user = "uid=authelia,ou=people,${config.services.lldap.settings.ldap_base_dn}";
					};
				};
				session = {
					inactivity = "30d";
					expiration = "6h";
					remember_me = "90d";
					cookies = [
						{
							name = "authelia_session_${cfg.auth.sessionName}";
							domain = cfg.auth.baseDomain;
							authelia_url = "https://${cfg.hosts.auth.domain}";
							default_redirection_url = "https://${cfg.baseDomain}";
						}
					];
				};
				storage.local.path = "/var/lib/authelia-main/db.sqlite3";
				access_control.default_policy = "one_factor";
				notifier.filesystem.filename = "/var/lib/authelia-main/notifications.txt";
				log.format = "text";
			};
			environmentVariables = {
				# for some reason not available in services.authelia.instances.main.secrets
				AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = config.age.secrets.lldapAutheliaPassword.path;
			};
		};
		
		## LLDAP
		
		modules.webServer.hosts.account = {
			proxyPort = ports.lldapWeb;
		};
		
		services.lldap = {
			enable = true;
			settings = {
				ldap_port = ports.lldap;
				http_port = ports.lldapWeb;
				http_url = "https://${cfg.hosts.account.domain}";
				# admin user
				ldap_user_dn = "dav";
				ldap_user_email = "david@dav.dev";
				# shouldn't really matter
				ldap_base_dn="dc=dav,dc=dev";
				key_seed_file = config.age.secrets.lldapKeySeed.path;
				ldap_user_pass_file = config.age.secrets.lldapAdminPassword.path;
				force_ldap_user_pass_reset = "always";
			};
		};
		
		users.users.lldap = {
			group = "lldap";
			isSystemUser = true;
		};
		
		users.groups.lldap = {};
		
		systemd.services.lldap.serviceConfig = {
			User = lib.mkForce "lldap";
			Group = lib.mkForce "lldap";
			DynamicUser = lib.mkForce false; # user is needed for age secret
		};
	};
}
