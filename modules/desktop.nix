{ self, pkgs, ... }:

{
	services.xserver.enable = true;
	
	services.displayManager.sddm.enable = true;
	services.xserver.desktopManager.plasma5.enable = true;
	
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
		keepass
		thunderbird
		self.packages.x86_64-linux.alacritty
	];
	
	fonts.packages = let
		nerdfonts = pkgs.nerdfonts.override {
			fonts = ["JetBrainsMono"];
		};
	in [
		nerdfonts
	];
}
