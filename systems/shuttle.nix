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
	
	boot.kernelParams = [
		"panic=30"
	];
	
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
		mealie.enable = true;
		filebrowser.enable = true;
		torrent.enable = true;
		yamtrack.enable = true;
	};
	
	# shuttle's cpu doesn't support x86_64-v2
	nixpkgs.overlays = [(final: prev: {
		immich-machine-learning = prev.immich-machine-learning.override {
			python3 = final.python3.override {
				packageOverrides = finalPy: prevPy: {
					numpy = prevPy.numpy.overrideAttrs (prevAttrs: {
						mesonFlags = (prevAttrs.mesonFlags or []) ++ [ "-Dcpu-baseline=none" ];
					});
				};
			};
		};
	})];
}
