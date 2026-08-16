{ pkgs, ... }:

{
	programs.bash = {
		enable = true;
		interactiveShellInit = ''
			exec nu
		'';
	};
	
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
