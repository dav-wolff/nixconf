{ config, lib, pkgs, ... }:

let
	cfg = config.modules.webServer;
	inherit (config) ports;
	inherit (lib) mkIf;
	inherit (pkgs) authing;
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
		
		# auth = { ... } in web-auth.nix
		
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
					headers = mkIf config.defaultHeaders (lib.mapAttrs (_: lib.mkDefault) {
						strict-transport-security = "max-age=63072000; includesubdomains; preload";
						referrer-policy = "same-origin";
						content-security-policy = "frame-ancestors 'self'; default-src 'self' 'unsafe-inline' 'wasm-unsafe-eval' data: blob:";
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
		
		makeHeaders = isProxy: headers: lib.concatStringsSep "\n" (
			lib.mapAttrsToList (name: value: ''
				${lib.optionalString isProxy "proxy_hide_header ${name};"}
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
					# use IPv4 address instead of localhost as some services aren't listening on IPv6
					proxy_pass http://127.0.0.1:${toString location.proxyPort};
				''}
				${ifNotNull location.redirect ''
					return 301 ${location.redirect};
				''}
				${lib.optionalString location.auth "include ${authing.authRequest};"}
				${makeHeaders (location.proxyPort != null) location.headers}
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
				${lib.optionalString host.auth ''
					# use IPv4 address instead of localhost as authing isn't listening on IPv6
					set $authing_upstream http://127.0.0.1:${toString ports.authing};
					include ${authing.authLocation};
				''}
				${lib.concatStringsSep "\n" (lib.mapAttrsToList makeLocation host.locations)}
			}
		'';
	in {
		modules.webServer.auth.enable = lib.any (hostConfig: hostConfig.auth) (lib.attrValues cfg.hosts);
		
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
	});
}
