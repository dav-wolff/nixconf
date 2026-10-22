{ config, pkgs, ... }:

{
	programs.bash = {
		enable = true;
		interactiveShellInit = ''
			exec nu
		'';
	};
	
	modules.nix.overlays = [(final: prev: {
		configured = prev.configured // {
			nushell = prev.configured.nushell.override {
				systemd-services = config.systemd.services;
				systemd-user-services = config.systemd.user.services;
			};
		};
	})];
	
	environment = {
		systemPackages = with pkgs; [
			fzf
			wl-clipboard
			jq
			bat
			xplr
			tree
			ripgrep
			fd
			configured.nushell
			configured.zsh
			configured.zellij
			configured.helix
		];
		
		sessionVariables = {
			EDITOR = "hx";
		};
	};
	
	users = {
		defaultUserShell = pkgs.bash;
		users.root.ignoreShellProgramCheck = true;
		users.dav.ignoreShellProgramCheck = true;
	};
	
	console = {
		earlySetup = true;
		font = "ter-u16n";
		packages = [pkgs.terminus_font];
	};
}
