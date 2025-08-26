{ ... }:
{ config, ... }:

{
	age.secrets = {
		porkbunApiKey = {
			file = ../secrets/minPorkbunApiKey.age;
			owner = "acmed";
		};
		porkbunApiSecret = {
			file = ../secrets/minPorkbunApiSecret.age;
			owner = "acmed";
		};
		spaceshipApiKey = {
			file = ../secrets/minSpaceshipApiKey.age;
			owner = "acmed";
		};
		spaceshipApiSecret = {
			file = ../secrets/minSpaceshipApiSecret.age;
			owner = "acmed";
		};
	};
	
	modules = {
		ssh.server = {
			enable = true;
			public = true;
		};
		
		webServer = {
			enable = true;
			baseDomain = "min.dav.dev";
			defaultCert = "main";
			auth = {
				baseDomain = "dav.dev";
				sessionName = "min";
			};
		};
		
		acme = {
			porkbunApiKey = config.age.secrets.porkbunApiKey.path;
			porkbunApiSecret = config.age.secrets.porkbunApiSecret.path;
			spaceshipApiKey = config.age.secrets.spaceshipApiKey.path;
			spaceshipApiSecret = config.age.secrets.spaceshipApiSecret.path;
			certs.main = {
				domain = "dav.dev";
				subdomain = "min";
				provider = "porkbun";
			};
			certs.git = {
				domain = "dav.dev";
				subdomain = "git";
				provider = "porkbun";
			};
		};
		
		forgejo = {
			enable = true;
			dataDir = "/var/lib/forgejo";
		};
		
		webServer.hosts.forgejo = {
			domain = "git.dav.dev";
			cert = "git";
		};
		
		solitaire.web = true;
		linky.enable = true;
		changedetection.enable = true;
	};
}
