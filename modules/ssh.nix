{ config, lib, ... }:

let
	cfg = config.modules.ssh;
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
			};
		}
		(lib.mkIf cfg.server.enable {
			modules.firewall.localAllowedTCPPorts = lib.mkIf (!cfg.server.public) [22];
			
			services.openssh = {
				enable = true;
				openFirewall = cfg.server.public;
				settings.PasswordAuthentication = false;
				settings.KbdInteractiveAuthentication = false;
			};
			
			users.users.dav.openssh.authorizedKeys.keys = (import ../public-keys.nix).allUserKeys;
		})
	];
}
