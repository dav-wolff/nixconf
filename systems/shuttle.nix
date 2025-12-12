{ nixos-hardware, ... }:
{ config, ... }:

{
	imports = [
		nixos-hardware.nixosModules.common-gpu-nvidia-disable
	];
	
	age.secrets = {
		porkbunApiKey = {
			file = ../secrets/shuttlePorkbunApiKey.age;
			owner = "acmed";
		};
		porkbunApiSecret = {
			file = ../secrets/shuttlePorkbunApiSecret.age;
			owner = "acmed";
		};
	};
	
	modules = {
		bootLoader = {
			enable = true;
			useGrub = true;
		};
		
		networking = {
			enable = true;
			useNetworkd = true;
		};
		
		ssh.server.enable = true;
		hotspot.enable = true;
		
		email = {
			domain = "dav.dev";
			cert = "dav.dev";
		};
		
		webServer = {
			enable = true;
			baseDomain = "dav.dev";
			defaultCert = "dav.dev";
			auth.replicaDomain = "min.dav.dev";
		};
		
		acme = {
			porkbunApiKey = config.age.secrets.porkbunApiKey.path;
			porkbunApiSecret = config.age.secrets.porkbunApiSecret.path;
			certs."dav.dev".provider = "porkbun";
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
		filebrowser.enable = true;
		torrent.enable = true;
	};
}
