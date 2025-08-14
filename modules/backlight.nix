{ config, lib, ... }:

let
	cfg = config.modules.backlight;
in {
	options.modules.backlight.enable = lib.mkEnableOption "backlight";
	
	config = lib.mkIf cfg.enable {
		hardware.acpilight.enable = true;
		users.users.dav.extraGroups = [
			"video"
		];
	};
}
