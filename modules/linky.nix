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
						LINKY_ICON_16=${assets}/icon_16.png
						LINKY_ICON_32=${assets}/icon_32.png
						LINKY_ICON_48=${assets}/icon_48.png
						LINKY_ICON_64=${assets}/icon_64.png
						LINKY_ICON_96=${assets}/icon_96.png
						LINKY_ICON_144=${assets}/icon_144.png
						LINKY_ICON_192=${assets}/icon_192.png
						LINKY_BANNER_JPG=${assets}/banner.jpg
						LINKY_FACE_JPG=${assets}/face.jpg
						LINKY_FACE_125_WEBP=${assets}/face_125.webp
						LINKY_FACE_250_WEBP=${assets}/face_250.webp
						LINKY_FACE_500_WEBP=${assets}/face_500.webp
						LINKY_FACE_1000_WEBP=${assets}/face_1000.webp
						LINKY_NAME=$(jq -r .name $secret)
						LINKY_URL=$(jq -r .url $secret)
						LINKY_INSTAGRAM=$(jq -r .instagram $secret)
						LINKY_BLUESKY=$(jq -r .bluesky $secret)
						LINKY_TWITTER=$(jq -r .twitter $secret)
						LINKY_TELEGRAM=$(jq -r .telegram $secret)
						LINKY_BANNER_THUMBHASH=$(jq -r .banner $secret)
						LINKY_FACE_THUMBHASH=$(jq -r .face $secret)
						export LINKY_ICON_16
						export LINKY_ICON_32
						export LINKY_ICON_48
						export LINKY_ICON_64
						export LINKY_ICON_96
						export LINKY_ICON_144
						export LINKY_ICON_192
						export LINKY_BANNER_JPG
						export LINKY_FACE_JPG
						export LINKY_FACE_125_WEBP
						export LINKY_FACE_250_WEBP
						export LINKY_FACE_500_WEBP
						export LINKY_FACE_1000_WEBP
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
		
		modules.webServer.hosts.linky = {
			domainFile = config.age.secrets.linkyDomain.path;
			cert = "linky";
			auth = false;
			robots = false;
			locations."/" = {
				files = config.age.derivedSecrets.linky.path;
				immutable = false;
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
