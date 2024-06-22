{
	services.openssh = {
		enable = true;
		settings.PasswordAuthentication = false;
		settings.KbdInteractiveAuthentication = false;
	};
	
	users.users.dav.openssh.authorizedKeys.keys = [
		"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIII7qaNDRTHgkgaPBsc2X7N7Aovw2s+uBhNAQLfYfqe4 david@dav.dev" # max
	];
}
