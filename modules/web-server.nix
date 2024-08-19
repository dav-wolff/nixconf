{ config, lib, pkgs, ... }:

let
	cfg = config.modules.webServer;
in {
	options.modules.webServer = let
		hostOptions = name: {
			enable = lib.mkEnableOption "webServer.${name}";
			subdomain = lib.mkOption {
				type = lib.types.str;
			};
			domain = lib.mkOption {
				type = lib.types.str;
				default = "${cfg.${name}.subdomain}.${cfg.domain}";
			};
		};
		
		hostOptionsWithPort = name: hostOptions name // {
			port = lib.mkOption {
				type = lib.types.port;
			};
		};
	in {
		enable = lib.mkEnableOption "webServer";
		
		domain = lib.mkOption {
			type = lib.types.str;
		};
		
		vault = hostOptionsWithPort "vault";
		
		bitwarden = hostOptionsWithPort "bitwarden";
		
		immich = hostOptionsWithPort "immich";
		
		navidrome = hostOptionsWithPort "navidrome" // {
			passwordFile = lib.mkOption {
				type = lib.types.str;
			};
		};
		
		owntracks = hostOptionsWithPort "owntracks" // {
			passwordFile = lib.mkOption {
				type = lib.types.str;
			};
		};
		
		solitaire = hostOptions "solitaire";
	};
	
	config = lib.mkIf cfg.enable {
		networking.firewall.allowedTCPPorts = [80 443];
		
		security.acme.acceptTerms = true;
		security.acme.defaults.email = "david@dav.dev";
		
		security.acme.certs.${cfg.domain}.extraDomainNames = ["www.${cfg.domain}"]
			++ lib.optional cfg.vault.enable cfg.vault.domain
			++ lib.optional cfg.bitwarden.enable cfg.bitwarden.domain
			++ lib.optional cfg.immich.enable cfg.immich.domain
			++ lib.optional cfg.navidrome.enable cfg.navidrome.domain
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
				mkHost = name: hostConfig: lib.mkIf cfg.${name}.enable {
					${cfg.${name}.domain} = hostConfig // {
						forceSSL = true;
						useACMEHost = cfg.domain;
						
						locations = hostConfig.locations // {
							"= /robots.txt" = {
								return = "200 'User-agent: *\\nDisallow: /'";
							};
						};
					};
				};
			in lib.mkMerge [
				{
					${cfg.domain} = {
						forceSSL = true;
						enableACME = true;
						
						locations."/" = {
							return = "200 'Hello world'";
							extraConfig = ''
								add_header Content-Type text/plain;
							'';
						};
					};
					
					"www.${cfg.domain}" = {
						addSSL = true;
						useACMEHost = cfg.domain;
						locations."/".return = "301 https://${cfg.domain}$request_uri";
					};
				}
				
				(mkHost "vault" {
					locations."/".proxyPass = "http://localhost:${toString cfg.vault.port}";
				})
				
				(mkHost "bitwarden" {
					locations."/" = {
						proxyPass = "http://localhost:${toString cfg.bitwarden.port}";
						proxyWebsockets = true;
					};
				})
				
				(mkHost "immich" {
					extraConfig = ''
						# https://immich.app/docs/administration/reverse-proxy/
						client_max_body_size 10000M;
						proxy_read_timeout 600s;
						proxy_send_timeout 600s;
						send_timeout 600s;
					'';
					locations."/" = {
						proxyPass = "http://localhost:${toString cfg.immich.port}";
						proxyWebsockets = true;
					};
					locations."^~ /_app/immutable" = {
						root = pkgs.immich.web;
						tryFiles = "$uri $uri/ =404";
						extraConfig = ''
							add_header Cache-Control "public, max-age=604800, immutable";
						'';
					};
				})
				
				(mkHost "navidrome" {
					basicAuthFile = cfg.navidrome.passwordFile;
					locations."/" = {
						proxyPass = "http://localhost:${toString cfg.navidrome.port}";
					};
				})
				
				(mkHost "owntracks" {
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
				})
				
				(mkHost "solitaire" {
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
				})
			];
			
			# Reject connections on unknown hosts
			appendHttpConfig = let
				cert = config.security.acme.certs.${cfg.domain}.directory;
			in ''
				server {
					listen 80 default_server;
					listen 443 ssl default_server;
					
					ssl_certificate ${cert}/fullchain.pem;
					ssl_certificate_key ${cert}/key.pem;
					ssl_trusted_certificate ${cert}/chain.pem;
					
					return 444;
				}
			'';
		};
	};
}
