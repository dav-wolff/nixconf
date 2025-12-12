{ lib, ... }:

let
	ports = {
		email = 9000;
		vault = 9010;
		vaultwarden = 9020;
		immich = 9030;
		immichMachineLearning = 9031;
		navidrome = 9040;
		owntracks = 9050;
		changedetection = 9060;
		authelia = 9070;
		lldap = 9071;
		lldapWeb = 9072;
		authing = 9073;
		mealie = 9080;
		forgejo = 9090;
		filebrowser = 10000;
		qbittorrent = 10010;
	};
in {
	options.ports = with lib; mkOption {
		type = types.attrsOf types.port;
	};
	
	config.ports = lib.mapAttrs (_: lib.mkDefault) ports;
}
