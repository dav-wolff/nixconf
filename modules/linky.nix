{ config, lib, pkgs, ... }:

let
	cfg = config.modules.linky;
in {
	options.modules.linky.enable = lib.mkEnableOption "linky";
	
	config = lib.mkIf cfg.enable {
		age = {
			secrets = {
				linkyAssetsTar.file = ../secrets/linkyAssetsTar.age;
				linkyValuesJson.file = ../secrets/linkyValuesJson.age;
				linkyDomain.file = ../secrets/linkyDomain.age;
			};
			derivedSecrets = {
				linkyAssets = {
					secret = config.age.secrets.linkyAssetsTar.path;
					owner = "nginx";
					isDirectory = true;
					inputs = with pkgs; [gnutar];
					script = ''
						rm -rf $out
						mkdir -p $out
						cd $out
						tar -xf $secret;
					'';
				};
				
				linky = {
					secret = config.age.secrets.linkyValuesJson.path;
					owner = "nginx";
					isDirectory = true;
					inputs = with pkgs; [
						build-linky
						gnutar
						jq
					];
					script = let
						assets = config.age.derivedSecrets.linkyAssets.path;
					in ''
						LINKY_ASSETS=${assets}
						LINKY_NAME=$(jq -r .name $secret)
						LINKY_URL=$(jq -r .url $secret)
						LINKY_INSTAGRAM=$(jq -r .instagram $secret)
						LINKY_BLUESKY=$(jq -r .bluesky $secret)
						LINKY_TWITTER=$(jq -r .twitter $secret)
						LINKY_TELEGRAM=$(jq -r .telegram $secret)
						LINKY_BANNER_THUMBHASH=$(jq -r .banner $secret)
						LINKY_FACE_THUMBHASH=$(jq -r .face $secret)
						export LINKY_ASSETS
						export LINKY_NAME
						export LINKY_URL
						export LINKY_INSTAGRAM
						export LINKY_BLUESKY
						export LINKY_TWITTER
						export LINKY_TELEGRAM
						export LINKY_BANNER_THUMBHASH
						export LINKY_FACE_THUMBHASH
						build-linky $out
					'';
				};
			};
		};
		
		modules.webServer.hosts = {
			linky = {
				domainFile = config.age.secrets.linkyDomain.path;
				cert = "linky";
				auth = false;
				robots = false;
				locations."/" = {
					files = config.age.derivedSecrets.linky.path;
					immutable = false;
				};
			};
			linkyDemo = {
				subdomain = "linky";
				auth = false;
				robots = false;
				locations."/" = {
					files = pkgs.linky-demo;
					immutable = false;
				};
			};
		};
		
		modules.acme = {
			certs.linky = {
				domainFile = config.age.secrets.linkyDomain.path;
				provider = "spaceship";
			};
		};
	};
}
