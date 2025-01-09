{ config, lib, ... }:

let
	cfg = config.modules.sshServer;
in {
	options.modules.sshServer.enable = lib.mkEnableOption "sshServer";
	
	config = lib.mkIf cfg.enable {
		modules.firewall.localAllowedTCPPorts = [22];
		
		services.openssh = {
			enable = true;
			openFirewall = false;
			settings.PasswordAuthentication = false;
			settings.KbdInteractiveAuthentication = false;
		};
		
		users.users.dav.openssh.authorizedKeys.keys = (import ../public-keys.nix).allUserKeys;
	};
}
