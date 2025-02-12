{ config, lib, pkgs, ... }:

let
	cfg = config.modules.desktop;
in {
	options.modules.desktop.enable = lib.mkEnableOption "desktop";
	
	config = lib.mkIf cfg.enable {
		modules.fonts.enable = true;
		
		services.displayManager.sddm.enable = true;
		services.displayManager.sddm.wayland.enable = true;
		services.desktopManager.plasma6.enable = true;
		
		services.xserver.xkb = {
			layout = "us";
			variant = "altgr-intl";
		};
		
		services.pulseaudio.enable = false;
		security.rtkit.enable = true;
		services.pipewire = {
			enable = true;
			alsa.enable = true;
			alsa.support32Bit = true;
			pulse.enable = true;
			# If you want to use JACK applications, uncomment this
			#jack.enable = true;
		};
		
		programs.kdeconnect.enable = true;
		
		users.users.dav.packages = with pkgs; [
			firefox
			kate
			discord
			telegram-desktop
			spotify
			bitwarden-desktop
			keepass
			thunderbird
			protonmail-desktop
			configured.alacritty
		];
	};
}
