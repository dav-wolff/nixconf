{ nixos-hardware, ... }:

{
	imports = [
		nixos-hardware.nixosModules.common-gpu-nvidia-disable
	];
	
	modules = {
		bootLoader = {
			enable = true;
			useGrub = true;
		};
		
		networking.enable = true;
		sshServer.enable = true;
		hotspot.enable = true;
		
		webServer = {
			enable = true;
			domain = "dav.dev";
			solitaire = {
				enable = true;
				subdomain = "solitaire";
			};
		};
		
		vault = {
			enable = true;
			port = 3103;
		};
		
		vaultwarden = {
			enable = true;
			port = 8222;
		};
		
		immich = {
			enable = true;
			port = 8333;
		};
		
		navidrome = {
			enable = true;
			port = 8444;
			passwordFile = ../secrets/navidromePassword.age;
		};
		
		owntracks = {
			enable = true;
			port = 8555;
			passwordFile = ../secrets/owntracksPassword.age;
		};
		
		changedetection = {
			enable = true;
			port = 8666;
			passwordFile = ../secrets/changedetectionPassword.age;
		};
	};
}
