let
	userKeys = {
		max = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIII7qaNDRTHgkgaPBsc2X7N7Aovw2s+uBhNAQLfYfqe4 david@dav.dev";
		top = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3VE3LCcpzIc8HKgZ1JZtheHJKsQ+QFjCrXB5/RuGBH david@dav.dev";
		sub = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP1argtOi0LVxZDkfoWmc0/5uG6p4JIyFKEm8wRyG4Rs david@dav.dev";
		shuttle = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMcgcxUDXSuNmHkmBiVte8zIQCRAiw/LX4TA3/M0dvb9 dav@dav.dev";
		android = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIObcELaGxc5/NMmexQvgbX3AMQkH7881vwQv1y8bIIy4 Main";
	};
	
	hostKeys = {
		max = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIbFDtbeU7fZREtiNRBaL0T8Ro599HO6t3h5NmzWNJ6Q root@max";
		top = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ/mtD2gnkt0pvRXKh7AUn7mPQ2TMqdaHLQfsPCDPhB6 root@top";
		sub = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICvLiK2OfWukN/GqwmWaCQVDHfyhn/LsE+OQXqaheFOE root@sub";
		shuttle = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAdIp/YIm2ncVFMmEqtg7y4cbnzP1tjX2Jx/YXRJsT15 root@shuttle";
		min = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK7skAFKlwq+YAs6HDKMf5uuYgpXeqbc4CW6qXkRBzmK root@min";
	};
	
	applicationKeys = {
		lldapPushdb = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM309OsAn2f+lzQTzKKGT6y9ajOZHhU+T6JRal6hXNPt";
	};
in {
	inherit userKeys hostKeys applicationKeys;
	
	allUserKeys = builtins.attrValues userKeys;
	allHostKeys = builtins.attrValues hostKeys;
	
	sshKnownHosts = {
		"min.dav.dev" = hostKeys.min;
	};
}
