{ config, lib, pkgs, ... }:

let
	cfg = config.modules.owntracks;
	inherit (config) ports;
in {
	options.modules.owntracks.enable = lib.mkEnableOption "owntracks";
	
	config = lib.mkIf cfg.enable {
		modules.webServer.hosts.owntracks = {
			locations = {
				"/" = {
					files = pkgs.owntracks-frontend;
					immutable = false;
				};
				"/pub".proxyPort = ports.owntracks;
				"/api".proxyPort = ports.owntracks;
			};
		};
		
		users.users.owntracks = {
			group = "owntracks";
			isSystemUser = true;
		};
		
		users.groups.owntracks = {};
		
		systemd.services.owntracks = let
			ot-recorder-wrapped = pkgs.writeShellScript "ot-recorder-wrapped" ''
				mkdir -p $STATE_DIRECTORY/last
				${pkgs.owntracks-recorder}/bin/ot-recorder \
					--storage $STATE_DIRECTORY \
					--doc-root usr/share/ot-recorder \
					--port 0 \ # disable MQTT
					--http-port ${toString ports.owntracks}
			'';
		in {
			description = "Owntracks";
			wants = ["network-online.target"];
			after = ["network-online.target"];
			wantedBy = ["multi-user.target"];
			
			serviceConfig = {
				WorkingDirectory = "${pkgs.owntracks-recorder}";
				ExecStart = "${ot-recorder-wrapped}";
				User="owntracks";
				Group="owntracks";
				StateDirectory = "owntracks";
				StateDirectoryMode ="0700";
			};
		};
	};
}
