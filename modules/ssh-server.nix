{
	services.openssh = {
		enable = true;
		settings.PasswordAuthentication = false;
		settings.KbdInteractiveAuthentication = false;
	};
	
	users.users.dav.openssh.authorizedKeys.keys = [
		"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIII7qaNDRTHgkgaPBsc2X7N7Aovw2s+uBhNAQLfYfqe4 david@dav.dev" # max
		"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP1argtOi0LVxZDkfoWmc0/5uG6p4JIyFKEm8wRyG4Rs david@dav.dev" # sub
	];
}
