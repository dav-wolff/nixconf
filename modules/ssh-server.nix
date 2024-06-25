{
	services.openssh = {
		enable = true;
		settings.PasswordAuthentication = false;
		settings.KbdInteractiveAuthentication = false;
	};
	
	users.users.dav.openssh.authorizedKeys.keys = (import ../public-keys.nix).allUserKeys;
}
