# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, ... }:

{
	
	time.timeZone = "Europe/Berlin";
	
	i18n.defaultLocale = "en_US.UTF-8";
	
	i18n.extraLocaleSettings = {
		LC_ADDRESS = "en_US.UTF-8";
		LC_IDENTIFICATION = "en_US.UTF-8";
		LC_MEASUREMENT = "en_US.UTF-8";
		LC_MONETARY = "en_US.UTF-8";
		LC_NAME = "en_US.UTF-8";
		LC_NUMERIC = "en_US.UTF-8";
		LC_PAPER = "en_US.UTF-8";
		LC_TELEPHONE = "en_US.UTF-8";
		LC_TIME = "en_US.UTF-8";
	};
	
	users.users.dav = {
		isNormalUser = true;
		description = "David";
		extraGroups = [ "networkmanager" "wheel" ];
	};
	
	environment.systemPackages = with pkgs; [
		pinentry-tty
		rbw
		fzf
		xsel
		bat
		nil
		xplr
		tree
		nix-tree
		lazygit
		backy
		configured.helix
		configured.zsh
		configured.zellij
		ndent
		journal
	];
	
	environment.shells = [pkgs.configured.zsh];
	users.defaultUserShell = pkgs.configured.zsh;
	# TODO is it better to use programs.zsh.enable?
	users.users.root.ignoreShellProgramCheck = true;
	users.users.dav.ignoreShellProgramCheck = true;
	
	console = {
		earlySetup = true;
		font = "ter-u16n";
		packages = [pkgs.terminus_font];
	};
	
	programs.ssh = {
		startAgent = true;
	};
	
	# local dns resolution
	services.avahi = {
		enable = true;
		nssmdns4 = true;
	};
	
	environment.sessionVariables = {
		EDITOR = "hx";
	};
	
	# This value determines the NixOS release from which the default
	# settings for stateful data, like file locations and database versions
	# on your system were taken. It‘s perfectly fine and recommended to leave
	# this value at the release version of the first install of this system.
	# Before changing this value read the documentation for this option
	# (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
	system.stateVersion = "24.05"; # Did you read the comment?
}
