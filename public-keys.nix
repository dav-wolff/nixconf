let
	userKeys = {
		max = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIII7qaNDRTHgkgaPBsc2X7N7Aovw2s+uBhNAQLfYfqe4 david@dav.dev";
		sub = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP1argtOi0LVxZDkfoWmc0/5uG6p4JIyFKEm8wRyG4Rs david@dav.dev";
		shuttle = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMcgcxUDXSuNmHkmBiVte8zIQCRAiw/LX4TA3/M0dvb9 dav@dav.dev";
	};
	
	hostKeys = {
		max = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIbFDtbeU7fZREtiNRBaL0T8Ro599HO6t3h5NmzWNJ6Q root@max";
		shuttle = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAdIp/YIm2ncVFMmEqtg7y4cbnzP1tjX2Jx/YXRJsT15 root@shuttle";
	};
in {
	inherit userKeys hostKeys;
	
	allUserKeys = builtins.attrValues userKeys;
	allHostKeys = builtins.attrValues hostKeys;
}
