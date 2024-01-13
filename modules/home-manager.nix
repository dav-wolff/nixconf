{ home-manager, ... }:

{
	imports = [
		(import "${home-manager}/nixos")
	];
	
	home-manager.users.dav = {
		home.stateVersion = "23.11";
		
		programs.helix = {
			enable = true;
			
			settings = {
				editor = {
					mouse = false;
					line-number = "relative";
					cursor-shape.insert = "bar";
					scrolloff = 8;
					cursorline = true;
					idle-timeout = 0;
					bufferline = "multiple";
					color-modes = true;
					true-color = true;
					auto-format = false;
					whitespace = {
						render.space = "all";
						render.tab = "all";
						render.newline = "none";
						characters = {
							space = "·";
							nbsp = "⍽";
							tab = "├"; /* ├╌╌╌ */
							tabpad = "╌";
						};
					};
				};
				keys = {
					normal.space = {
						i = ":toggle-option lsp.display-inlay-hints";
					};
				};
			};
		};
		
		programs.zellij = {
			enable = true;
		};
		
		home.file.".config/zellij/config.kdl".source = ../appconf/zellij.kdl;
		
		programs.gitui = {
			enable = true;
		};
	};
}
