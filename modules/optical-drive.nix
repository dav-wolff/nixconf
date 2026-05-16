{ config, lib, ...}:

let
	cfg = config.modules.opticalDrive;
in {
	options.modules.opticalDrive.enable = lib.mkEnableOption "opticalDrive";
	
	config = lib.mkIf cfg.enable {
		programs.k3b.enable = true;
		services.udisks2.enable = true;
		users.users.dav.extraGroups = ["cdrom"];
	};
}
