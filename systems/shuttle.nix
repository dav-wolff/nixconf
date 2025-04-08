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
		ssh.server.enable = true;
		hotspot.enable = true;
		
		email.domain = "dav.dev";
		
		webServer = {
			enable = true;
			baseDomain = "dav.dev";
		};
		
		immich = {
			enable = true;
			remoteMachineLearningHost = "max";
		};
		
		solitaire.web = true;
		vault.enable = true;
		vaultwarden.enable = true;
		navidrome.enable = true;
		owntracks.enable = true;
		changedetection.enable = true;
		mealie.enable = true;
	};
}
