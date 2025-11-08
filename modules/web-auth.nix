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
		replicaDomain = lib.mkOption {
			type = types.nullOr types.str;
			default = null;
		};
	};
	
	config = lib.mkIf cfg.enable { # TODO: cfg.auth.enable
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
			lldapPushdbSshPrivateKey = {
				file = ../secrets/lldapPushdbSshPrivateKey.age;
				owner = "lldap";
			};
		};
		
		## Authing
		
		modules.webServer.hosts.authing = {
			subdomain = "auth";
			auth = false;
			proxyPort = ports.authing;
		};
		
		services.authing = {
			enable = true;
			settings = {
				port = config.ports.authing;
				base_domain = config.modules.webServer.baseDomain;
				url = "https://${config.modules.webServer.hosts.authing.domain}";
			};
		};
		
		## Authelia
		
		modules.webServer.hosts.authelia = {
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
							authelia_url = "https://${cfg.hosts.authelia.domain}";
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
		
		users.users.lldap = lib.mkMerge [{
			group = "lldap";
			isSystemUser = true;
		}
		(lib.mkIf (cfg.auth.replicaDomain == null) {
			openssh.authorizedKeys.keys = [
				(import ../public-keys.nix).applicationKeys.lldapPushdb
			];
			packages = with pkgs; [
				sqlite-rsync
			];
			# required for ssh login
			useDefaultShell = true;
		})];
		
		users.groups.lldap = {};
		
		systemd.services.lldap.serviceConfig = {
			User = lib.mkForce "lldap";
			Group = lib.mkForce "lldap";
			DynamicUser = lib.mkForce false; # user is needed for age secret
		};
		
		systemd.services.lldap-pushdb = let
			sshWrapped = pkgs.writeShellScript "ssh-with-lldap-identity" ''
				set -e
				
				ssh -i ${config.age.secrets.lldapPushdbSshPrivateKey.path} "$@"
			'';
			location = "/var/lib/lldap/users.db";
		in lib.mkIf (cfg.auth.replicaDomain != null) {
			wantedBy = [ "lldap.service" ];
			path = with pkgs; [
				openssh
				fswatch
				sqlite-rsync
			];
			script = ''
				sqlite3_rsync -v --ssh ${sshWrapped} ${location} ${cfg.auth.replicaDomain}:${location}
				# <--- TODO: possible race right here...
				fswatch --monitor poll_monitor --one-per-batch --latency 10 ${location} | while read; do
					sqlite3_rsync -v --ssh ${sshWrapped} ${location} ${cfg.auth.replicaDomain}:${location}
				done
			'';
			serviceConfig = {
				User = "lldap";
				Group = "lldap";
			};
		};
	};
}
