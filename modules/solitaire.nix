{ lib, config, pkgs, ... }:

let
	cfg = config.modules.solitaire;
in {
	options.modules.solitaire = {
		web = lib.mkEnableOption "solitaire-web";
		native = lib.mkEnableOption "solitaire-native" // {
			default = config.modules.desktop.enable;
		};
	};
	
	config = {
		environment.systemPackages = lib.mkIf cfg.native [pkgs.solitaire.native];
		
		modules.webServer.hosts.solitaire = lib.mkIf cfg.web {
			auth = false;
			locations = {
				"/".files = pkgs.solitaire.web;
				"= /index.html" = {
					files = pkgs.solitaire.web;
					immutable = false;
				};
			};
		};
	};
}
