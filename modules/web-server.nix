{ config, lib, pkgs, ... }:

let
	cfg = config.modules.webServer;
	inherit (config) ports;
	inherit (pkgs) unindent;
	inherit (lib) mkIf mkMerge;
	
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
in {
	options.modules.webServer = let
		inherit (lib) mkEnableOption mkOption types;
	in {
		enable = mkEnableOption "webServer";
		
		baseDomain = mkOption {
			type = types.str;
		};
		
		defaultCert = mkOption {
			type = types.nullOr types.str;
			default = null;
		};
		
		hosts = let
			hostOptions = {config, ...}: {
				options = {
					enable = mkOption {
						type = types.bool;
						default = true;
					};
					subdomain = mkOption {
						type = types.str;
						default = config._module.args.name;
					};
					domain = mkOption {
						type = types.str;
						default = "${config.subdomain}.${cfg.baseDomain}";
					};
					domainFile = mkOption {
						type = types.nullOr types.path;
						default = null;
					};
					cert = mkOption {
						type = types.str;
						default = cfg.defaultCert;
					};
					auth = mkOption {
						type = types.bool;
						default = true;
					};
					robots = mkOption {
						type = types.bool;
						default = true;
					};
					maxBodySize = mkOption {
						type = types.nullOr types.str;
						default = null;
					};
					proxyPort = mkOption {
						type = types.nullOr types.port;
						default = null;
					};
					redirect = mkOption {
						type = types.nullOr types.str;
						default = null;
					};
					defaultHeaders = mkOption {
						type = types.bool;
						default = true;
					};
					headers = mkOption {
						type = types.attrsOf (types.nullOr types.str);
						default = {};
					};
					locations = mkOption {
						type = types.attrsOf (types.submodule (locationOptions config));
						default = {};
					};
					extraConfig = mkOption {
						type = types.str;
						default = "";
					};
				};
				
				config = {
					locations."/" = mkIf (config.proxyPort != null || config.redirect != null) {
						inherit (config) proxyPort redirect;
					};
					locations."= /robots.txt" = mkIf config.robots {
						staticText = "User-agent: *\\nDisallow: /";
						auth = false;
					};
					locations."/internal/authelia/authz" = mkIf config.auth {
						extraConfig = "include ${authLocation};";
						auth = false;
					};
					headers = mkIf config.defaultHeaders (lib.mapAttrs (_: lib.mkDefault) {
						strict-transport-security = "max-age=63072000; includesubdomains; preload";
						referrer-policy = "same-origin";
						content-security-policy = "frame-ancestors 'none'; default-src 'self' 'unsafe-inline' 'wasm-unsafe-eval' data: blob:";
						x-content-type-options = "nosniff";
						x-frame-options = "deny";
					});
				};
			};
			
			locationOptions = host: {config, ...}: {
				options = {
					immutable = mkOption {
						type = types.bool;
						default = config.files != null;
					};
					files = mkOption {
						type = types.nullOr types.path;
						default = null;
					};
					staticText = mkOption {
						type = types.nullOr types.str;
						default = null;
					};
					proxyPort = mkOption {
						type = types.nullOr types.port;
						default = null;
					};
					redirect = mkOption {
						type = types.nullOr types.str;
						default = null;
					};
					auth = mkOption {
						type = types.bool;
						default = host.auth;
					};
					headers = mkOption {
						type = types.attrsOf (types.nullOr types.str);
						default = {};
					};
					extraConfig = mkOption {
						type = types.str;
						default = "";
					};
				};
				
				config = {
					headers = host.headers // {
						cache-control = mkIf config.immutable "public, max-age=604800, immutable";
					};
				};
			};
		in mkOption {
			type = types.attrsOf (types.submodule hostOptions);
			default = {};
		};
	};
	
	config = mkIf cfg.enable (let
		enableAuth = lib.any (hostConfig: hostConfig.auth) (lib.attrValues cfg.hosts);
		
		proxyHeaders = pkgs.writeText "proxy-headers.conf" ''
			proxy_http_version 1.1;
			proxy_set_header Upgrade $http_upgrade;
			proxy_set_header Connection $connection_upgrade;
			proxy_set_header Host $host;
			proxy_set_header X-Real-IP $remote_addr;
			proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
			proxy_set_header X-Forwarded-Proto $scheme;
			proxy_set_header X-Forwarded-Host $host;
			proxy_set_header X-Forwarded-Server $host;
		'';
		
		makeHeaders = headers: lib.concatStringsSep "\n" (
			lib.mapAttrsToList (name: value: ''
				proxy_hide_header ${name};
				add_header ${name} "${value}";
			'')
				(lib.filterAttrs (name: value:
					assert (builtins.match "([a-z]|-)*" name) != null; # make sure all headers are lowercase, otherwise they're not combined properly
					value != null)
				headers)
		);
		
		makeLocation = path: location: let
			ifNotNull = value: lib.optionalString (value != null);
		in ''
			location ${path} {
				${ifNotNull location.files ''
					try_files $uri $uri/ =404;
					root ${location.files};
				''}
				${ifNotNull location.staticText ''
					add_header content-type text/plain;
					return 200 '${location.staticText}';
				''}
				${ifNotNull location.proxyPort ''
					include ${proxyHeaders};
					proxy_pass http://localhost:${toString location.proxyPort};
				''}
				${ifNotNull location.redirect ''
					return 301 ${location.redirect};
				''}
				${lib.optionalString location.auth "include ${authRequest};"}
				${makeHeaders location.headers}
				${location.extraConfig}
			}
		'';
		
		makeHost = name: host: let
			cert = config.modules.acme.certs.${host.cert};
		in ''
			server {
				listen 0.0.0.0:80;
				listen [::0]:80;
				${lib.optionalString (host.domainFile == null) "server_name ${host.domain};"}
				${lib.optionalString (host.domainFile != null) "include ${config.age.derivedSecrets.${"nginx-server-name-${name}"}.path};"}
				location / {
					return 301 https://$host$request_uri;
				}
			}
			server {
				listen 0.0.0.0:443 ssl;
				listen [::0]:443 ssl;
				${lib.optionalString (host.domainFile == null) "server_name ${host.domain};"}
				${lib.optionalString (host.domainFile != null) "include ${config.age.derivedSecrets.${"nginx-server-name-${name}"}.path};"}
				http2 on;
				ssl_certificate ${cert.certFile};
				ssl_certificate_key ${cert.privateKeyFile};
				access_log /var/log/nginx/${host.domain}.access.log log;
				${lib.optionalString (host.maxBodySize != null) "client_max_body_size ${host.maxBodySize};"}
				${host.extraConfig}
				${lib.concatStringsSep "\n" (lib.mapAttrsToList makeLocation host.locations)}
			}
		'';
	in mkMerge [
		{
			assertions = let
				checkLocation = _: location: {
					assertion = lib.count (a: a != null) (with location; [files staticText proxyPort redirect]) <= 1;
					message = "can only use one of files, staticText, proxyPort, or redirect";
				};
				checkHost = _: hostConfig: lib.mapAttrsToList checkLocation hostConfig.locations;
			in lib.flatten (lib.mapAttrsToList checkHost cfg.hosts);
			
			modules.webServer.hosts = {
				"@" = {
					domain = cfg.baseDomain;
					auth = false;
					locations."/".staticText = "Hello world";
				};
				www = {
					auth = false;
					robots = false;
					redirect = "https://${cfg.baseDomain}$request_uri";
				};
				auth = {
					enable = enableAuth;
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
			};
			
			age.derivedSecrets = let
				hosts = lib.filterAttrs (_: host: host.domainFile != null) cfg.hosts;
			in lib.mapAttrs' (name: host: {
				name = "nginx-server-name-${name}";
				value = {
					secret = host.domainFile;
					owner = "nginx";
					script = ''
						echo "server_name $(cat $secret);"
					'';
				};
			}) hosts;
			
			networking.firewall.allowedTCPPorts = [80 443];
			
			modules.acme = {
				enable = true;
				users = [config.services.nginx.user];
			};
			
			systemd.services.nginx = {
				after = ["acmed.service"];
				wants = ["acmed.service"];
			};
			
			services.nginx = {
				enable = true;
				recommendedProxySettings = true;
				recommendedTlsSettings = true;
				recommendedOptimisation = true;
				recommendedGzipSettings = true;
				recommendedZstdSettings = true;
				recommendedBrotliSettings = true;
				
				commonHttpConfig = ''
					map $remote_addr $ip_truncated {
						~^(?P<ip>\d+.\d+.\d+). $ip.0;
						~^(?P<ip>[^:]+[^:]+): $ip::;
						default 0.0.0.0;
					}
					
					log_format log '[$time_local] $ip_truncated "$request" $status Sent:$body_bytes_sent Ref:"$http_referrer" "$http_user_agent"';
					log_format host_log '[$time_local] $http_host $ip_truncated "$request" $status Sent:$body_bytes_sent Ref:"$http_referrer" "$http_user_agent"';
				'';
				
				appendHttpConfig = let
					cert = config.modules.acme.certs.${cfg.defaultCert};
				in ''
					# Reject connections on unknown hosts
					server {
						listen 80 default_server;
						listen 443 ssl default_server;
						
						access_log /var/log/nginx/access.log host_log;
						
						ssl_certificate ${cert.certFile};
						ssl_certificate_key ${cert.privateKeyFile};
						
						return 444;
					}
					${lib.concatStringsSep "\n" (lib.mapAttrsToList makeHost (lib.filterAttrs (_: host: host.enable) cfg.hosts))}
				'';
			};
		}
		
		## Authelia
		
		(mkIf enableAuth {
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
			};
		})
	]);
}
