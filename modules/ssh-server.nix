{ config, lib, ... }:

let
	cfg = config.modules.sshServer;
in {
	options.modules.sshServer = {
		enable = lib.mkEnableOption "sshServer";
		public = lib.mkOption {
			type = lib.types.bool;
			default = false;
		};
	};
	
	config = lib.mkIf cfg.enable {
		modules.firewall.localAllowedTCPPorts = lib.mkIf (!cfg.public) [22];
		
		services.openssh = {
			enable = true;
			openFirewall = cfg.public;
			settings.PasswordAuthentication = false;
			settings.KbdInteractiveAuthentication = false;
		};
		
		users.users.dav.openssh.authorizedKeys.keys = (import ../public-keys.nix).allUserKeys;
	};
}
