{ config, lib, pkgs, ... }:

let
	cfg = config.modules.firewall;
	canonicalizePortList = ports: lib.unique (builtins.sort builtins.lessThan ports);
in {
	options.modules.firewall = {
		localAllowedTCPPorts = lib.mkOption {
			type = lib.types.listOf lib.types.port;
			default = [];
			apply = canonicalizePortList;
		};
		localAllowedUDPPorts = lib.mkOption {
			type = lib.types.listOf lib.types.port;
			default = [];
			apply = canonicalizePortList;
		};
	};
	
	config = {
		networking.nftables.enable = true;
		networking.firewall.extraInputRules = let
			concatPorts = ports: lib.concatStringsSep ", " (map (port: toString port) ports);
			tcpPorts = concatPorts cfg.localAllowedTCPPorts;
			udpPorts = concatPorts cfg.localAllowedUDPPorts;
			mkRule = proto: ports: ''
				${proto} dport {${ports}} ip saddr {10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16} counter log flags all prefix "Good: " accept
				${proto} dport {${ports}} counter log level alert flags all prefix "Request from foreign address on sensitive port: " drop
			'';
		in ''
			${lib.optionalString (tcpPorts != "") (mkRule "tcp" tcpPorts)}
			${lib.optionalString (udpPorts != "") (mkRule "udp" udpPorts)}
		'';
	};
}
