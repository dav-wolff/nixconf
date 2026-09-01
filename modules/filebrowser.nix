{ config, lib, pkgs, ... }:

let
	cfg = config.modules.filebrowser;
	inherit (config) ports;
in {
	options.modules.filebrowser = {
		enable = lib.mkEnableOption "filebrowser";
		volume = lib.mkOption {
			type = lib.types.str;
		};
	};
	
	config = lib.mkIf cfg.enable (let
		user = "filebrowser-quantum";
		home = "/var/lib/filebrowser-quantum";
		json = pkgs.formats.json {};
		filebrowserConfig = json.generate "filebrowser-quantum-config.yaml" {
			server = {
				port = ports.filebrowser-quantum;
				database = "${home}/database.db";
				sources = [
					{
						path = "${cfg.volume}/users";
						name = "Users";
						config = {
							defaultEnabled = true;
							createUserDir = true;
						};
					}
				];
			};
			http = {
				disableRateLimit = true;
			};
			auth = {
				adminUsername = "dav";
				methods = {
					password.enabled = false;
					proxy = {
						enabled = true;
						header = "Remote-User";
						logoutRedirectUrl = "https://${config.modules.webServer.hosts.authing.domain}/logout";
					};
				};
			};
			userDefaults = {
				permissions = {
					create = true;
					modify = true;
					delete = true;
					download = true;
					share = true;
					realtime = true;
				};
			};
		};
	in {
		modules.webServer.hosts.filebrowser = {
			subdomain = "files";
			proxyPort = ports.filebrowser-quantum;
			authing.share_link = {
				check_regex = "^/public/share/([0-9a-zA-Z\\-]+)$";
				check_rewrite = "/public/api/share/info?hash=$1";
				allow_regex = "^/public/";
				redirect = "http://127.0.0.1:${toString ports.filebrowser-quantum}";
			};
		};
		
		users.users.${user} = {
			inherit home;
			isSystemUser = true;
			group = user;
			createHome = true;
		};
		
		users.groups.${user} = { };
		
		systemd.services.filebrowser-quantum = {
			wantedBy = ["multi-user.target"];
			after = ["network.target"];
			serviceConfig = {
				User = user;
				Group = user;
				WorkingDirectory = home;
				ExecStart = "${lib.getExe pkgs.filebrowser-quantum} -c ${filebrowserConfig}";
				Restart = "on-failure";
			};
		};
		
		systemd.tmpfiles.rules = [
			"d ${cfg.volume}/users 0750 ${user} ${user} -"
		];
	});
}
