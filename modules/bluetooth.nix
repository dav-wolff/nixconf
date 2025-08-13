{ config, lib, pkgs, ... }:

let
	cfg = config.modules.bluetooth;
in {
	options.modules.bluetooth.enable = lib.mkEnableOption "bluetooth";
	
	config = lib.mkIf cfg.enable {
		hardware.bluetooth.enable = true;
		
		environment.systemPackages = with pkgs; [
			bluetui
		];
	};
}
