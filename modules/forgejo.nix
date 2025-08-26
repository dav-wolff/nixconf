{ config, lib, ... }:

let
	cfg = config.modules.forgejo;
	inherit (config) ports;
in {
	options.modules.forgejo = {
		enable = lib.mkEnableOption "forgejo";
		dataDir = lib.mkOption {
			type = lib.types.str;
		};
	};
	
	config = lib.mkIf cfg.enable {
		modules.webServer.hosts.forgejo = {
			subdomain = "git";
			proxyPort = ports.forgejo;
			maxBodySize = "512M";
		};
		
		# set user to git for nicer ssh urls
		users.users.git = {
			# https://github.com/NixOS/nixpkgs/blob/3b9f00d7a7bf68acd4c4abb9d43695afb04e03a5/nixos/modules/services/misc/forgejo.nix#L795
			home = config.services.forgejo.stateDir;
			useDefaultShell = true;
			group = config.services.forgejo.group;
			isSystemUser = true;
		};
		
		services.forgejo = {
			enable = true;
			user = "git";
			stateDir = cfg.dataDir;
			database.type = "sqlite3";
			# enable if it's ever needed
			lfs.enable = false;
			settings = {
				# TODO: doesn't seem to be working
				DEFAULT.APP_DISPLAY_NAME_FORMAT = "{APP_NAME}";
				server = {
					DOMAIN = config.modules.webServer.hosts.forgejo.domain;
					ROOT_URL = "https://${config.modules.webServer.hosts.forgejo.domain}/";
					HTTP_PORT = ports.forgejo;
				};
				service = {
					DISABLE_REGISTRATION = true;
					ENABLE_REVERSE_PROXY_AUTHENTICATION = true;
					# TODO: documentation says "the reverse proxy is responsible for ensuring that no CSRF is possible"
					# does authelia protect against this?
					ENABLE_REVERSE_PROXY_AUTHENTICATION_API = false;
					ENABLE_REVERSE_PROXY_AUTO_REGISTRATION = true;
					ENABLE_REVERSE_PROXY_EMAIL = true;
					ENABLE_REVERSE_PROXY_FULL_NAME = true;
					
				};
				security = {
					# TODO: typo sensitive, use config.modules.webServer...
					REVERSE_PROXY_AUTHENTICATION_USER = "Remote-User";
					REVERSE_PROXY_AUTHENTICATION_EMAIL = "Remote-Email";
					REVERSE_PROXY_AUTHENTICATION_FULL_NAME = "Remote-Name";
					REVERSE_PROXY_LIMIT = 1; # requests forwarded through one reverse proxy
				};
				repository = {
					ENABLE_PUSH_CREATE_USER = true;
					ENABLE_PUSH_CREATE_ORG = true;
					# not quite sure what this does, but prefer ssh over https for repository urls
					GO_GET_CLONE_URL_PROTOCOL = "ssh";
					DISABLED_REPO_UNITS = "repo.wiki,repo.ext_wiki";
					DISABLE_STARS = true;
				};
			};
		};
	};
}
