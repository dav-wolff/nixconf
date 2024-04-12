# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ self, pkgs, name, ndent, journal, ... }:

{
	nix.settings.experimental-features = [
		"nix-command"
		"flakes"
	];
	
	nixpkgs.config.allowUnfree = true;
	
	networking.hostName = name;
	
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
	
	services.printing.enable = true;
	
	users.users.dav = {
		isNormalUser = true;
		description = "David";
		extraGroups = [ "networkmanager" "wheel" ];
	};
	
	environment.systemPackages = with pkgs; [
		xsel
		bat
		nil
		gcc
		xplr
		nix-tree
		lazygit
		self.packages.x86_64-linux.helix
		self.packages.x86_64-linux.zellij
		ndent.packages.x86_64-linux.ndent
		journal.packages.x86_64-linux.journal
	];
	
	programs.git = {
		enable = true;
			config = {
			user.name = "David Wolff";
			user.email = "david@dav.dev";
			init.defaultBranch = "master";
			alias = {
				c = "commit -m";
				co = "checkout";
				s = "status";
				a = "add";
				l = "log --oneline";
			};
		};
	};
	
	programs.ssh = {
		startAgent = true;
	};
	
	# local dns resolution
	services.avahi = {
		enable = true;
		nssmdns = true;
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
	system.stateVersion = "22.11"; # Did you read the comment?
}
