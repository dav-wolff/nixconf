{ self, pkgs, ... }:

let
	inherit (pkgs) system;
in
{
	imports = [
		./fonts.nix
	];
	
	services.displayManager.sddm.enable = true;
	services.displayManager.sddm.wayland.enable = true;
	services.desktopManager.plasma6.enable = true;
	
	services.xserver.xkb = {
		layout = "us";
		variant = "altgr-intl";
	};
	
	sound.enable = true;
	hardware.pulseaudio.enable = false;
	security.rtkit.enable = true;
	services.pipewire = {
		enable = true;
		alsa.enable = true;
		alsa.support32Bit = true;
		pulse.enable = true;
		# If you want to use JACK applications, uncomment this
		#jack.enable = true;
	};
	
	users.users.dav.packages = with pkgs; [
		firefox
		kate
		discord
		telegram-desktop
		spotify
		bitwarden-desktop
		keepass
		thunderbird
		self.packages.${system}.alacritty
	];
}
