{ config, lib, pkgs, ... }:

let
	cfg = config.modules.ssh;
	inherit (pkgs) unindent;
	publicKeys = import ../public-keys.nix;
	knownHosts = builtins.mapAttrs (name: publicKey: {
		inherit publicKey;
	}) publicKeys.sshKnownHosts;
in {
	options.modules.ssh.server = {
		enable = lib.mkEnableOption "sshServer";
		public = lib.mkOption {
			type = lib.types.bool;
			default = false;
		};
	};
	
	config = lib.mkMerge [{
			programs.ssh = {
				startAgent = true;
				inherit knownHosts;
				extraConfig = unindent ''
					Host ssh.*
						ProxyCommand proxytunnel -p %h:443 -E -d %h:%p -C /etc/ssl/certs/ca-certificates.crt -P %r
				'';
			};
			
			environment.systemPackages = with pkgs; [
				proxytunnel
			];
		}
		(lib.mkIf cfg.server.enable {
			modules.firewall.localAllowedTCPPorts = lib.mkIf (!cfg.server.public) [22];
			
			modules.webServer.hosts.ssh = {
				locations."/" = {
					extraConfig = ''
						tunnel_pass localhost:22;
					'';
				};
			};
			
			services.authing.settings = {
				groups = ["ssh"];
				hosts.ssh = {
					host = config.modules.webServer.hosts.ssh.domain;
					allow_group = "ssh";
				};
			};
			
			services.openssh = let
				banner = pkgs.runCommandLocal "ssh-banner.txt" {} ''
					${lib.getExe pkgs.figlet} ${config.networking.hostName} > $out
				'';
			in {
				enable = true;
				openFirewall = cfg.server.public;
				settings = {
					PasswordAuthentication = false;
					KbdInteractiveAuthentication = false;
					Banner = "${banner}";
				};
				inherit knownHosts;
			};
			
			users.users.dav.openssh.authorizedKeys.keys = publicKeys.allUserKeys;
		})
	];
}
