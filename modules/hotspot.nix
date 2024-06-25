{ config, pkgs, ... }:

let
	name = "shuttle";
	wifi = "wlp3s0";
	internet = "enp2s0f5";
in
{
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
}
