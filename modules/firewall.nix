{ config, lib, ... }:

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
		forceVpn = {
			enable = lib.mkOption {
				type = lib.types.bool;
				default = cfg.forceVpn.members != [];
			};
			address = lib.mkOption {
				type = lib.types.str;
			};
			interface = lib.mkOption {
				type = lib.types.str;
			};
			members = lib.mkOption {
				type = lib.types.listOf lib.types.str;
				default = [];
			};
		};
	};
	
	config = {
		networking.nftables = {
			enable = true;
			checkRuleset = true;
			preCheckRuleset = ''
				sed 's/skuid {.*}/skuid {"nobody"}/g' -i ruleset.conf
			'';
			tables.restrict-output = lib.mkIf cfg.forceVpn.enable {
				name = "restrict-output";
				family = "inet";
				content = let
					users = lib.concatMapStringsSep ", " (user: ''"${user}"'') cfg.forceVpn.members;
				in ''
					chain output {
						type filter hook output priority 0; policy accept;
						meta skuid {${users}} counter goto output-force-vpn
					}
					
					chain output-force-vpn {
						meta oif "lo" accept
						meta oifname "${cfg.forceVpn.interface}" accept
						ip daddr ${cfg.forceVpn.address} accept
						meta nftrace set 1 counter reject
					}
				'';
			};
		};
		
		# make sure network doesn't come online without the firewall running
		systemd.services.systemd-networkd = lib.mkIf config.systemd.network.enable {
			after = ["nftables.service"];
			bindsTo = ["nftables.service"];
		};
		
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
