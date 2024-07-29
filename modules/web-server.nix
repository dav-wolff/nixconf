{ config, lib, pkgs, ... }:

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
		
		immich = {
			enable = lib.mkEnableOption "webServer.immich";
			subdomain = lib.mkOption {
				type = lib.types.str;
			};
			domain = lib.mkOption {
				type = lib.types.str;
				default = "${cfg.immich.subdomain}.${cfg.domain}";
			};
			port = lib.mkOption {
				type = lib.types.port;
			};
		};
		
		owntracks = {
			enable = lib.mkEnableOption "webServer.owntracks";
			subdomain = lib.mkOption {
				type = lib.types.str;
			};
			domain = lib.mkOption {
				type = lib.types.str;
				default = "${cfg.owntracks.subdomain}.${cfg.domain}";
			};
			port = lib.mkOption {
				type = lib.types.port;
			};
			passwordFile = lib.mkOption {
				type = lib.types.str;
			};
		};
		
		solitaire = {
			enable = lib.mkEnableOption "webServer.solitaire";
			subdomain = lib.mkOption {
				type = lib.types.str;
			};
			domain = lib.mkOption {
				type = lib.types.str;
				default = "${cfg.solitaire.subdomain}.${cfg.domain}";
			};
		};
	};
	
	config = lib.mkIf cfg.enable {
		networking.firewall.allowedTCPPorts = [80 443];
		
		security.acme.acceptTerms = true;
		security.acme.defaults.email = "david@dav.dev";
		
		security.acme.certs.${cfg.domain}.extraDomainNames = ["www.${cfg.domain}"]
			++ lib.optional cfg.vault.enable cfg.vault.domain
			++ lib.optional cfg.bitwarden.enable cfg.bitwarden.domain
			++ lib.optional cfg.immich.enable cfg.immich.domain
			++ lib.optional cfg.owntracks.enable cfg.owntracks.domain
			++ lib.optional cfg.solitaire.enable cfg.solitaire.domain;
		
		services.nginx = {
			enable = true;
			recommendedProxySettings = true;
			recommendedTlsSettings = true;
			recommendedOptimisation = true;
			recommendedGzipSettings = true;
			recommendedZstdSettings = true;
			recommendedBrotliSettings = true;
			
			virtualHosts = let
				baseHosts = let
					locations."/" = {
						return = "200 'Hello world'";
						extraConfig = ''
							add_header Content-Type text/plain;
						'';
					};
				in {
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
				};
				
				vaultHosts = lib.mkIf cfg.vault.enable {
					${cfg.vault.domain} = {
						forceSSL = true;
						useACMEHost = cfg.domain;
						locations."/".proxyPass = "http://localhost:${toString cfg.vault.port}";
					};
				};
				
				bitwardenHosts = lib.mkIf cfg.bitwarden.enable {
					${cfg.bitwarden.domain} = {
						forceSSL = true;
						useACMEHost = cfg.domain;
						locations."/" = {
							proxyPass = "http://localhost:${toString cfg.bitwarden.port}";
							proxyWebsockets = true;
						};
					};
				};
				
				immichHosts = lib.mkIf cfg.immich.enable {
					${cfg.immich.domain} = {
						forceSSL = true;
						useACMEHost = cfg.domain;
						locations."/" = {
							proxyPass = "http://localhost:${toString cfg.immich.port}";
							proxyWebsockets = true;
						};
						extraConfig = ''
							# https://immich.app/docs/administration/reverse-proxy/
							client_max_body_size 10000M;
							proxy_read_timeout 600s;
							proxy_send_timeout 600s;
							send_timeout 600s;
						'';
					};
				};
				
				owntracksHosts = lib.mkIf cfg.owntracks.enable {
					${cfg.owntracks.domain} = {
						forceSSL = true;
						useACMEHost = cfg.domain;
						basicAuthFile = cfg.owntracks.passwordFile;
						locations."/" = {
							root = pkgs.owntracks-frontend;
						};
						locations."/pub" = {
							proxyPass = "http://localhost:${toString cfg.owntracks.port}";
						};
						locations."/api" = {
							proxyPass = "http://localhost:${toString cfg.owntracks.port}";
						};
					};
				};
				
				solitaireHosts = lib.mkIf cfg.solitaire.enable {
					${cfg.solitaire.domain} = {
						forceSSL = true;
						useACMEHost = cfg.domain;
						locations."= /index.html" = {
							root = pkgs.solitaire.web;
							extraConfig = ''
								add_header Cache-Control "public, no-cache";
							'';
						};
						locations."/" = {
							root = pkgs.solitaire.web;
							extraConfig = ''
								add_header Cache-Control "public, max-age=604800, immutable";
							'';
						};
					};
				};
			in lib.mkMerge [baseHosts vaultHosts bitwardenHosts immichHosts owntracksHosts solitaireHosts];
		};
	};
}
