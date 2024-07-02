{ config, lib, ... }:

let
	cfg = config.modules.bootLoader;
in {
	options.modules.bootLoader = {
		enable = lib.mkEnableOption "bootLoader";
		useGrub = lib.mkOption {
			default = false;
			type = lib.types.bool;
		};
	};
	
	config = lib.mkIf cfg.enable {
		boot.loader.grub = lib.mkIf cfg.useGrub {
			enable = true;
			device = "/dev/sda";
		};
		
		boot.loader.systemd-boot = lib.mkIf (!cfg.useGrub) {
			enable = true;
		};
		
		boot.loader.efi = lib.mkIf (!cfg.useGrub) {
			canTouchEfiVariables = true;
			efiSysMountPoint = "/boot/efi";
		};
	};
}
