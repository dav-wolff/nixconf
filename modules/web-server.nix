{
	networking.firewall.allowedTCPPorts = [80 443];
	
	security.acme.acceptTerms = true;
	security.acme.defaults.email = "dav-wolff@outlook.com";
	
	security.acme.certs."dav.dev".extraDomainNames = ["www.dav.dev" "vault.dav.dev"];
	
	services.nginx = let
		locations."/" = {
			return = "200 'Hello world'";
			extraConfig = ''
				add_header Content-Type text/plain;
			'';
		};
	in {
		enable = true;
		virtualHosts = {
			"dav.dev" = {
				forceSSL = true;
				enableACME = true;
				inherit locations;
			};
			
			"www.dav.dev" = {
				forceSSL = true;
				useACMEHost = "dav.dev";
				inherit locations;
			};
			
			"vault.dav.dev" = {
				forceSSL = true;
				useACMEHost = "dav.dev";
				locations."/".proxyPass = "http://localhost:3103";
			};
		};
	};
}
