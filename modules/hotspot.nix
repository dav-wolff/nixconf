{ config, lib, pkgs, ... }:

let
	cfg = config.modules.hotspot;
	name = config.networking.hostName;
	wifi = "wlp0s29f7u5";
	internet = "enp2s0f5";
in {
	options.modules.hotspot.enable = lib.mkEnableOption "hotspot";
	
	config = lib.mkIf cfg.enable {
		networking.firewall.allowedUDPPorts = [67];
		
		age.secrets.hotspotPassword.file = ../secrets/hotspotPassword.age;
		
		systemd.services.create_ap = {
			wantedBy = [ "multi-user.target" ];
			description = "Create AP Service";
			after = [ "network.target" ];
			serviceConfig = {
				EnvironmentFile = config.age.secrets.hotspotPassword.path;
				ExecStart = "${pkgs.linux-wifi-hotspot}/bin/create_ap ${wifi} ${internet} ${name} $HOTSPOT_PASSWORD";
				KillSignal = "SIGINT";
				Restart = "on-failure";
			};
		};
	};
}
