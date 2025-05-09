{ config, lib, pkgs, ... }:

let
	cfg = config.modules.webServer;
	inherit (config) ports;
	inherit (pkgs) unindent;
in {
	options.modules.webServer = with lib; {
		enable = lib.mkEnableOption "webServer";
		
		baseDomain = lib.mkOption {
			type = lib.types.str;
		};
		
		auth = {
			subdomain = lib.mkOption {
				type = lib.types.str;
				default = "auth";
			};
			domain = lib.mkOption {
				type = lib.types.str;
				default = "${cfg.auth.subdomain}.${cfg.baseDomain}";
			};
		};
		
		hosts = let
			hostOptions = {config, ...}: {
				options = {
					subdomain = mkOption {
						type = types.str;
						default = config._module.args.name;
					};
					domain = mkOption {
						type = types.str;
						default = "${config.subdomain}.${cfg.baseDomain}";
					};
					auth = mkOption {
						type = types.bool;
						default = true;
					};
					proxyPort = mkOption {
						type = types.nullOr types.port;
						default = null;
					};
					locations = mkOption {
						type = types.attrsOf (types.submodule locationOptions);
						default = {};
					};
					extraConfig = mkOption {
						type = types.nullOr types.str;
						default = null;
					};
				};
				
				config = {
					locations."/" = mkIf (config.proxyPort != null) {
						inherit (config) proxyPort;
					};
				};
			};
			
			locationOptions = {config, ...}: {
				options = {
					immutable = mkOption {
						type = types.bool;
						default = config.files != null;
					};
					files = mkOption {
						type = types.nullOr types.path;
						default = null;
					};
					proxyPort = mkOption {
						type = types.nullOr types.port;
						default = null;
					};
				};
			};
		in mkOption {
			type = types.attrsOf (types.submodule hostOptions);
			default = {};
		};
	};
	
	config = lib.mkIf cfg.enable (let
		enableAuth = lib.any (hostConfig: hostConfig.auth) (lib.attrValues cfg.hosts);
	in lib.mkMerge [
		{
			assertions = let
				checkLocation = _: locationConfig: {
					assertion = locationConfig.files == null || locationConfig.proxyPort == null;
					message = "can't simultaneously proxy requests and serve static files";
				};
				checkHost = _: hostConfig: lib.mapAttrsToList checkLocation hostConfig.locations;
			in lib.flatten (lib.mapAttrsToList checkHost cfg.hosts);
			
			networking.firewall.allowedTCPPorts = [80 443];
			
			modules.acme = {
				enable = true;
				domain = cfg.baseDomain;
				extraDomains = ["www.${cfg.baseDomain}"];
				users = [config.services.nginx.user];
			};
			
			services.nginx = {
				enable = true;
				recommendedProxySettings = true;
				recommendedTlsSettings = true;
				recommendedOptimisation = true;
				recommendedGzipSettings = true;
				recommendedZstdSettings = true;
				recommendedBrotliSettings = true;
				
				virtualHosts = let
					robotsLocation = {
						"= /robots.txt" = {
							return = "200 'User-agent: *\\nDisallow: /'";
						};
					};
					
					authRequest = pkgs.writeText "authelia-authrequest.conf" ''
						auth_request /internal/authelia/authz;
						
						auth_request_set $user $upstream_http_remote_user;
						auth_request_set $groups $upstream_http_remote_groups;
						auth_request_set $name $upstream_http_remote_name;
						auth_request_set $email $upstream_http_remote_email;
						
						proxy_set_header Remote-User $user;
						proxy_set_header Remote-Groups $groups;
						proxy_set_header Remote-Email $email;
						proxy_set_header Remote-Name $name;
						
						auth_request_set $redirection_url $upstream_http_location;
						error_page 401 =302 $redirection_url;
					'';
					
					authLocation = pkgs.writeText "authelia-location.conf" ''
						internal;
						proxy_pass http://localhost:${toString ports.authelia}/api/authz/auth-request;
						
						proxy_set_header X-Original-Method $request_method;
						proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
						proxy_set_header X-Forwarded-For $remote_addr;
						proxy_set_header Content-Length "";
						proxy_set_header Connection "";
						
						proxy_pass_request_body off;
						proxy_redirect http:// $scheme://;
						proxy_http_version 1.1;
						proxy_cache_bypass $cookie_session;
						proxy_no_cache $cookie_session;
						proxy_buffers 4 32k;
						client_body_buffer_size 128k;
						
						send_timeout 5m;
						proxy_read_timeout 240;
						proxy_send_timeout 240;
						proxy_connect_timeout 240;
					'';
					
					hosts = lib.mapAttrs (name: hostConfig: {
						serverName = hostConfig.domain;
						forceSSL = true;
						enableACME = true;
						
						locations = lib.mkMerge [
							(lib.mapAttrs (_: locationConfig: {
								root = locationConfig.files;
								tryFiles = lib.mkIf (locationConfig.files != null) "$uri $uri/ =404";
								proxyPass = lib.mkIf (locationConfig.proxyPort != null) "http://localhost:${toString locationConfig.proxyPort}";
								proxyWebsockets = locationConfig.proxyPort != null;
								extraConfig = lib.mkMerge [
									(lib.mkIf hostConfig.auth ''
										include ${authRequest};
									'')
									(lib.mkIf locationConfig.immutable ''
										add_header Cache-Control "public, max-age=604800, immutable";
									'')
								];
							}) hostConfig.locations)
							{
								"= /robots.txt".return = "200 'User-agent: *\\nDisallow: /'";
							}
							(lib.mkIf hostConfig.auth {
								"/internal/authelia/authz".extraConfig = ''
									include ${authLocation};
								'';
							})
						];
						
						extraConfig = lib.mkMerge [
							(lib.mkIf (hostConfig.extraConfig != null) hostConfig.extraConfig)
							''
								access_log /var/log/nginx/${hostConfig.domain}.access.log log;
							''
						];
					}) cfg.hosts;
				in lib.mkMerge [
					hosts
					{
						${cfg.baseDomain} = {
							forceSSL = true;
							enableACME = true;
							
							locations."/" = {
								return = "200 'Hello world'";
								extraConfig = ''
									add_header Content-Type text/plain;
								'';
							};
							
							extraConfig = ''
								access_log /var/log/nginx/${cfg.baseDomain}.access.log log;
							'';
						};
						
						"www.${cfg.baseDomain}" = {
							addSSL = true;
							useACMEHost = cfg.baseDomain;
							locations."/".return = "301 https://${cfg.baseDomain}$request_uri";
							
							extraConfig = ''
								access_log /var/log/nginx/www.${cfg.baseDomain}.access.log log;
							'';
						};
					}
					
					(lib.mkIf enableAuth (let
						location = {
							proxyPass = "http://localhost:${toString ports.authelia}";
						};
					in {
						${cfg.auth.domain} = {
							forceSSL = true;
							enableACME = true;
							
							locations = robotsLocation // {
								"/" = location;
								"= /api/verify" = location;
								"/api/authz/" = location;
							};
						};
					}))
				];
				
				commonHttpConfig = ''
					map $remote_addr $ip_truncated {
						~^(?P<ip>\d+.\d+.\d+). $ip.0;
						~^(?P<ip>[^:]+[^:]+): $ip::;
						default 0.0.0.0;
					}
					
					log_format log '[$time_local] $ip_truncated "$request" $status Sent:$body_bytes_sent Ref:"$http_referrer" "$http_user_agent"';
					log_format host_log '[$time_local] $http_host $ip_truncated "$request" $status Sent:$body_bytes_sent Ref:"$http_referrer" "$http_user_agent"';
				'';
				
				# Reject connections on unknown hosts
				appendHttpConfig = let
					cert = config.security.acme.certs.${cfg.baseDomain}.directory;
				in ''
					
					server {
						listen 80 default_server;
						listen 443 ssl default_server;
						
						access_log /var/log/nginx/access.log host_log;
						
						ssl_certificate ${cert}/fullchain.pem;
						ssl_certificate_key ${cert}/key.pem;
						ssl_trusted_certificate ${cert}/chain.pem;
						
						return 444;
					}
				'';
			};
		}
		
		## Authelia
		
		(lib.mkIf enableAuth {
			age.secrets = {
				autheliaJwtSecret = {
					file = ../secrets/autheliaJwtSecret.age;
					owner = config.services.authelia.instances.main.user;
				};
				autheliaStorageEncryptionKey = {
					file = ../secrets/autheliaStorageEncryptionKey.age;
					owner = config.services.authelia.instances.main.user;
				};
				autheliaOidcHmac = {
					file = ../secrets/autheliaOidcHmac.age;
					owner = config.services.authelia.instances.main.user;
				};
				autheliaOidcPrivateKey = {
					file = ../secrets/autheliaOidcPrivateKey.age;
					owner = config.services.authelia.instances.main.user;
				};
			};
			
			services.authelia.instances.main = let
				usersFile = pkgs.writeText "authelia-users.yml" (unindent ''
					users:
					  dav:
					    disabled: false
					    displayname: dav
					    email: david@dav.dev
					    password: $argon2id$v=19$m=65536,t=3,p=4$tJilRMOcf7kfNiM8DbagUw$I3Lf5HlaHM69hw7FI6E4qWsWxGQMijhyff8OIpbjz3k
				'');
			in {
				enable = true;
				secrets = {
					jwtSecretFile = config.age.secrets.autheliaJwtSecret.path;
					storageEncryptionKeyFile = config.age.secrets.autheliaStorageEncryptionKey.path;
					oidcHmacSecretFile = config.age.secrets.autheliaOidcHmac.path;
					oidcIssuerPrivateKeyFile = config.age.secrets.autheliaOidcPrivateKey.path;
				};
				settings = {
					theme = "dark";
					server = {
						address = "tcp://:${toString ports.authelia}/";
						endpoints.authz.auth-request.implementation = "AuthRequest";
					};
					authentication_backend.file.path = usersFile;
					session = {
						inactivity = "30d";
						expiration = "6h";
						remember_me = "90d";
						cookies = [
							{
								domain = cfg.baseDomain;
								authelia_url = "https://${cfg.auth.domain}";
								default_redirection_url = "https://${cfg.baseDomain}";
							}
						];
					};
					storage.local.path = "/var/lib/authelia-main/db.sqlite3";
					access_control.default_policy = "one_factor";
					notifier.filesystem.filename = "/var/lib/authelia-main/notifications.txt";
					log.format = "text";
				};
			};
		})
	]);
}
