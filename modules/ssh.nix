{ config, lib, ... }:

let
	cfg = config.modules.ssh;
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
			};
		}
		(lib.mkIf cfg.server.enable {
			modules.firewall.localAllowedTCPPorts = lib.mkIf (!cfg.server.public) [22];
			
			services.openssh = {
				enable = true;
				openFirewall = cfg.server.public;
				settings.PasswordAuthentication = false;
				settings.KbdInteractiveAuthentication = false;
				inherit knownHosts;
			};
			
			users.users.dav.openssh.authorizedKeys.keys = publicKeys.allUserKeys;
		})
	];
}
