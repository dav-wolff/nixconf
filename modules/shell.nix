{ pkgs, ... }:

{
	environment = {
		shells = [pkgs.configured.zsh];
		
		systemPackages = with pkgs; [
			fzf
			wl-clipboard
			jq
			bat
			xplr
			tree
			ripgrep
			configured.zsh
			configured.zellij
			configured.helix
		];
		
		sessionVariables = {
			EDITOR = "hx";
		};
	};
	
	users = {
		defaultUserShell = pkgs.configured.zsh;
		# TODO is it better to use programs.zsh.enable?
		users.root.ignoreShellProgramCheck = true;
		users.dav.ignoreShellProgramCheck = true;
	};
	
	console = {
		earlySetup = true;
		font = "ter-u16n";
		packages = [pkgs.terminus_font];
	};
}
