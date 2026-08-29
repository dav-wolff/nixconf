{ config, lib, pkgs, ... }:

let
	cfg = config.modules.immich;
	inherit (config) ports;
in {
	options.modules.immich = {
		enable = lib.mkEnableOption "immich";
		remoteMachineLearningHost = lib.mkOption {
			type = lib.types.str;
		};
		remoteMachineLearning = lib.mkOption {
			type = lib.types.bool;
			default = false;
		};
		volume = lib.mkOption {
			type = lib.types.str;
		};
	};
	
	config = lib.mkMerge [
		{
			environment.systemPackages = [pkgs.immich-cli];
		}
		(lib.mkIf cfg.enable (let
			settings = {
				newVersionCheck.enabled = false;
				server.externalDomain = "https://${config.modules.webServer.hosts.immich.domain}";
				machineLearning.urls = [
					"http://${cfg.remoteMachineLearningHost}.local:${toString ports.immichMachineLearning}" # TODO: https
					"http://localhost:${toString ports.immichMachineLearning}"
				];
				user.deleteDelay = 30;
				notifications.smtp = {
					enabled = true;
					from = "Immich <immich@${config.modules.email.domain}>";
					transport = {
						host = "localhost";
						port = ports.email;
						ignoreCert = true; # cert has public hostname, not localhost
						username = "mailuser";
						password = "@PASSWORD@";
					};
				};
			};
			
			jsonFormat = pkgs.formats.json {};
			settingsFile = jsonFormat.generate "immich.json" settings;
		in {
			modules.webServer.hosts.immich = {
				# auth is enabled but manually configured
				auth = false;
				proxyPort = ports.immich;
				maxBodySize = "10000M";
				headers.content-security-policy = null;
				extraConfig = ''
					# https://immich.app/docs/administration/reverse-proxy/
					proxy_read_timeout 600s;
					proxy_send_timeout 600s;
					send_timeout 600s;
					set $authing_upstream http://127.0.0.1:${toString ports.authing};
					include ${pkgs.authing.authLocation};
				'';
				# manually configure auth request,
				# skipping Set-Cookie as that currently crashed the mobile app
				locations."/".extraConfig = ''
					auth_request /internal/auth-request;
					
					auth_request_set $authing_redirection $upstream_http_location;
					auth_request_set $authing_cookies $upstream_http_set_cookie;
					auth_request_set $authing_www_authenticate $upstream_http_www_authenticate;
					
					auth_request_set $authing_user $upstream_http_remote_user;
					auth_request_set $authing_email $upstream_http_remote_email;
					auth_request_set $authing_name $upstream_http_remote_name;
					auth_request_set $authing_groups $upstream_http_remote_groups;
					
					proxy_set_header Remote-User $authing_user;
					proxy_set_header Remote-Email $authing_email;
					proxy_set_header Remote-Name $authing_name;
					proxy_set_header Remote-Groups $authing_groups;
					proxy_set_header Proxy-Authorization "";
					
					# add_header Set-Cookie $authing_cookies always;
					error_page 403 =302 $authing_redirection;
				'';
				# use regular auth requests with cookies enabled, so that share links work
				locations."/share/" = {
					proxyPort = ports.immich;
					extraConfig = ''
						include ${pkgs.authing.authRequest};
					'';
				};
				locations."^~ /_app/immutable".files = "${pkgs.immich}/lib/node_modules/immich/build/www";
				
				authing = {
					share_link = {
						path_regex = "^(/share/|/s/)[^/?]+";
						redirect = "http://127.0.0.1:${toString ports.immich}";
					};
				};
			};
			
			modules.email = {
				enable = true;
				senders = ["immich"];
			};
			
			age.derivedSecrets."immich.json" = {
				secret = config.age.secrets.opensmtpdPassword.path;
				owner = config.services.immich.user;
				inputs = with pkgs; [gnused];
				script = ''
					sed "s/@PASSWORD@/$(cat $secret)/g" ${settingsFile}
				'';
			};
			
			services.immich = {
				# nginx is currently not configured to reach ::1
				host = "127.0.0.1";
				enable = true;
				mediaLocation = cfg.volume;
				port = ports.immich;
				environment = {
					IMMICH_CONFIG_FILE = config.age.derivedSecrets."immich.json".path;
					TRUSTED_HEADER_LOGOUT = "https://${config.modules.webServer.hosts.authing.domain}/logout";
				};
				machine-learning.environment = {
					IMMICH_PORT = lib.mkForce (toString ports.immichMachineLearning);
				};
			};
			
			modules.immich.remoteMachineLearning = false;
		}))
		(lib.mkIf cfg.remoteMachineLearning {
			modules.firewall.localAllowedTCPPorts = [ports.immichMachineLearning];
			
			services.immich = {
				enable = true;
				database.enable = false;
				redis.enable = false;
				machine-learning.environment = {
					IMMICH_HOST = lib.mkForce "0.0.0.0";
					IMMICH_PORT = lib.mkForce (toString ports.immichMachineLearning);
				};
			};
			
			systemd.services.immich-server = lib.mkForce {};
		})
	];
}
