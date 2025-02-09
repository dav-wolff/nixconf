{ config, lib, ... }:

let
	cfg = config.modules.acme;
in {
	options.modules.acme = {
		enable = lib.mkEnableOption "acme";
		domain = lib.mkOption {
			type = lib.types.str;
		};
		extraDomains = lib.mkOption {
			type = lib.types.listOf lib.types.str;
			default = [];
		};
		users = lib.mkOption {
			type = lib.types.listOf lib.types.str;
		};
	};
	
	config = lib.mkIf cfg.enable {
		security.acme.acceptTerms = true;
		security.acme.defaults.email = "david@dav.dev";
		security.acme.certs.${cfg.domain} = {
			extraDomainNames = cfg.extraDomains;
			group = "acmeCertUsers";
		};
		
		users.groups.acmeCertUsers = {
			members = cfg.users;
		};
	};
}
