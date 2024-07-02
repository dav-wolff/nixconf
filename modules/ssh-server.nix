{ config, lib, ... }:

let
	cfg = config.modules.sshServer;
in {
	options.modules.sshServer.enable = lib.mkEnableOption "sshServer";
	
	config = lib.mkIf cfg.enable {
		services.openssh = {
			enable = true;
			settings.PasswordAuthentication = false;
			settings.KbdInteractiveAuthentication = false;
		};
		
		users.users.dav.openssh.authorizedKeys.keys = (import ../public-keys.nix).allUserKeys;
	};
}
