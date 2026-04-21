{ config, lib, pkgs, ... }:

let
	cfg = config.modules.bootLoader;
in {
	options.modules.bootLoader = {
		enable = lib.mkEnableOption "bootLoader";
		theme = lib.mkOption {
			default = null;
			type = lib.types.nullOr lib.types.str;
			# angular_alt https://raw.githubusercontent.com/adi1090x/files/master/plymouth-themes/previews/5.gif
			# black_hud https://raw.githubusercontent.com/adi1090x/files/master/plymouth-themes/previews/6.gif
			# dark_planet https://raw.githubusercontent.com/adi1090x/files/master/plymouth-themes/previews/23.gif
			# deus_ex https://raw.githubusercontent.com/adi1090x/files/master/plymouth-themes/previews/25.gif
			# square_hud https://raw.githubusercontent.com/adi1090x/files/master/plymouth-themes/previews/75.gif
		};
		useGrub = lib.mkOption {
			default = false;
			type = lib.types.bool;
		};
	};
	
	config = lib.mkIf cfg.enable (lib.mkMerge [
		(lib.mkIf cfg.useGrub {
			boot.loader.grub = lib.mkIf cfg.useGrub {
				enable = true;
				device = "/dev/sda";
			};
		})
		(lib.mkIf (!cfg.useGrub) {
			boot.loader = {
				systemd-boot.enable = true;
				efi = {
					canTouchEfiVariables = true;
					efiSysMountPoint = "/boot/efi";
				};
			};
		})
		(lib.mkIf (cfg.theme != null) {
			boot = {
				plymouth = lib.mkIf (cfg.theme != null) {
					enable = true;
					theme = cfg.theme;
					themePackages = [(pkgs.adi1090x-plymouth-themes.override {
						selected_themes = [cfg.theme];
					})];
				};
				
				consoleLogLevel = 3;
				initrd.verbose = false;
				kernelParams = [
					"quiet"
					"udev.log_level=3"
					"systemd.show_status=auto"
				];
				loader.timeout = 2;
			};
		})
	]);
}
