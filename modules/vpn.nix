{ config, lib, ... }:

let
	cfg = config.modules.vpn;
in {
	options.modules.vpn = {
		enable = lib.mkEnableOption "vpn";
		interface = lib.mkOption {
			type = lib.types.str;
			default = "vpn0";
		};
	};
	
	config = lib.mkIf cfg.enable (let
		address = "62.169.136.217";
	in {
		age.secrets = {
			wireguardPrivateKey = {
				file = ../secrets/wireguardPrivateKey;
			};
		};
		
		modules.firewall.forceVpn = {
			inherit address;
			inherit (cfg) interface;
		};
		
		# TODO: is this necessary? alternatives?
		networking.firewall.checkReversePath = "loose";
		
		networking.wireguard.interfaces.${cfg.interface} = {
			privateKeyFile = config.age.secrets.wireguardPrivateKey.path;
			table = "51280";
			ips = [
				"10.2.0.2/32"
			];
			peers = [
				{
					publicKey = "oNctPLp48sX2jk6U9hoER6QT4aGp6TEAUydA6VuA8h8=";
					allowedIPs = [
						"0.0.0.0/0"
						"::0/0"
					];
					endpoint = "${address}:51820";
				}
			];
		};
	});
}

