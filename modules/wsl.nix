{ config, lib, pkgs, ... }:

let
	cfg = config.modules.wsl;
in {
	imports = [
		./wsl/wsl-distro.nix
		./wsl/interop.nix
	];
	
	options.modules.wsl.enable = lib.mkEnableOption "wsl";
	
	config = lib.mkIf cfg.enable {
		modules.fonts.enable = true;
		
		wsl = {
			enable = true;
			automountPath = "/mnt";
			defaultUser = "dav";
			startMenuLaunchers = true;
			
			wslConf.network.hostname = config.networking.hostName;
		};
		
		environment.systemPackages = with pkgs; [
			configured.alacritty
		];
	};
}
