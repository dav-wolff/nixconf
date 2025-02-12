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
				auth = false;
				proxyPort = ports.immich;
				extraConfig = ''
					# https://immich.app/docs/administration/reverse-proxy/
					client_max_body_size 10000M;
					proxy_read_timeout 600s;
					proxy_send_timeout 600s;
					send_timeout 600s;
				'';
				locations."^~ /_app/immutable".files = pkgs.immich.web;
			};
			
			modules.email = {
				enable = true;
				senders = ["immich"];
			};
			
			age.derivedSecrets."immich.json" = {
				secret = config.age.secrets.opensmtpdPassword.path;
				inputs = with pkgs; [gnused];
				script = ''
					sed "s/@PASSWORD@/$(cat $secret)/g" ${settingsFile}
				'';
			};
			
			services.immich = {
				enable = true;
				mediaLocation = cfg.volume;
				port = ports.immich;
				environment = {
					IMMICH_CONFIG_FILE = config.age.derivedSecrets."immich.json".path;
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
