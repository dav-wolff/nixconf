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
		
		email.domain = "dav.dev";
		
		webServer = {
			enable = true;
			domain = "dav.dev";
			solitaire = {
				enable = true;
				subdomain = "solitaire";
			};
		};
		
		vault.enable = true;
		
		vaultwarden.enable = true;
		
		immich = {
			enable = true;
			remoteMachineLearningHost = "max";
		};
		
		navidrome = {
			enable = true;
			passwordFile = ../secrets/navidromePassword.age;
		};
		
		owntracks = {
			enable = true;
			passwordFile = ../secrets/owntracksPassword.age;
		};
		
		changedetection = {
			enable = true;
			passwordFile = ../secrets/changedetectionPassword.age;
		};
	};
}
