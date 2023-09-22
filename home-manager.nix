{ config, pkgs, ... }:

let
	home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
in
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
			};
		};
		
		programs.zellij = {
			enable = true;
		};
		
		home.file.".config/zellij/config.kdl".source = ./appconf/zellij.kdl;
		
		programs.gitui = {
			enable = true;
		};
	};
}