{ config, lib, pkgs, ... }:

let
	cfg = config.modules.owntracks;
in {
	options.modules.owntracks = {
		enable = lib.mkEnableOption "owntracks";
		port = lib.mkOption {
			type = lib.types.port;
		};
		passwordFile = lib.mkOption {
			type = lib.types.pathInStore;
		};
	};
	
	config = lib.mkIf cfg.enable {
		age.secrets.owntracksPassword = {
			file = cfg.passwordFile;
			owner = "nginx";
		};
		
		modules.webServer.owntracks = {
			enable = true;
			subdomain = "owntracks";
			port = cfg.port;
			passwordFile = config.age.secrets.owntracksPassword.path;
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
					--http-port ${toString cfg.port}
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
