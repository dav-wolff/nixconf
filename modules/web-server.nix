{ config, lib, ... }:

let
	cfg = config.modules.webServer;
in {
	options.modules.webServer = {
		enable = lib.mkEnableOption "webServer";
		
		domain = lib.mkOption {
			type = lib.types.str;
		};
		
		vault = {
			enable = lib.mkEnableOption "webServer.vault";
			subdomain = lib.mkOption {
				type = lib.types.str;
			};
			domain = lib.mkOption {
				type = lib.types.str;
				default = "${cfg.vault.subdomain}.${cfg.domain}";
			};
			port = lib.mkOption {
				type = lib.types.port;
			};
		};
		
		bitwarden = {
			enable = lib.mkEnableOption "webServer.bitwarden";
			subdomain = lib.mkOption {
				type = lib.types.str;
			};
			domain = lib.mkOption {
				type = lib.types.str;
				default = "${cfg.bitwarden.subdomain}.${cfg.domain}";
			};
			port = lib.mkOption {
				type = lib.types.port;
			};
		};
	};
	
	config = lib.mkIf cfg.enable {
		networking.firewall.allowedTCPPorts = [80 443];
		
		security.acme.acceptTerms = true;
		security.acme.defaults.email = "dav-wolff@outlook.com";
		
		security.acme.certs.${cfg.domain}.extraDomainNames = ["www.${cfg.domain}"]
			++ lib.optional cfg.vault.enable cfg.vault.domain
			++ lib.optional cfg.bitwarden.enable cfg.bitwarden.domain;
		
		services.nginx = let
			locations."/" = {
				return = "200 'Hello world'";
				extraConfig = ''
					add_header Content-Type text/plain;
				'';
			};
		in {
			enable = true;
			recommendedProxySettings = true;
			recommendedTlsSettings = true;
			recommendedOptimisation = true;
			recommendedGzipSettings = true;
			recommendedZstdSettings = true;
			recommendedBrotliSettings = true;
			
			virtualHosts = {
				${cfg.domain} = {
					forceSSL = true;
					enableACME = true;
					inherit locations;
				};
				
				"www.${cfg.domain}" = {
					forceSSL = true;
					useACMEHost = cfg.domain;
					inherit locations;
				};
			} // lib.optionalAttrs cfg.vault.enable {
				${cfg.vault.domain} = {
					forceSSL = true;
					useACMEHost = cfg.domain;
					locations."/".proxyPass = "http://localhost:${toString cfg.vault.port}";
				};
			} // lib.optionalAttrs cfg.bitwarden.enable {
				${cfg.bitwarden.domain} = {
					forceSSL = true;
					useACMEHost = cfg.domain;
					locations."/" = {
						proxyPass = "http://localhost:${toString cfg.bitwarden.port}";
						proxyWebsockets = true;
					};
				};
			};
		};
	};
}
