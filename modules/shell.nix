{ pkgs, ... }:

{
	environment = {
		shells = [pkgs.configured.nushell pkgs.configured.zsh];
		
		systemPackages = with pkgs; [
			fzf
			wl-clipboard
			jq
			bat
			xplr
			tree
			ripgrep
			fd
			configured.zsh
			configured.zellij
			configured.helix
		];
		
		sessionVariables = {
			EDITOR = "hx";
		};
	};
	
	users = {
		defaultUserShell = pkgs.configured.nushell;
		users.root.ignoreShellProgramCheck = true;
		users.dav.ignoreShellProgramCheck = true;
	};
	
	console = {
		earlySetup = true;
		font = "ter-u16n";
		packages = [pkgs.terminus_font];
	};
}
