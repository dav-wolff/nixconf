{ config, lib, pkgs, ... }:

let
	cfg = config.modules.wsl;
in {
	options.modules.wsl.enable = lib.mkEnableOption "wsl";
	
	config = lib.mkIf cfg.enable {
		modules.fonts.enable = true;
		
		wsl = {
			enable = true;
			defaultUser = "dav";
			startMenuLaunchers = true;
			
			wslConf.automount.root = "/mnt";
			wslConf.interop.enabled = false;
		};
		
		environment.systemPackages = with pkgs; [
			configured.alacritty
		];
	};
}
