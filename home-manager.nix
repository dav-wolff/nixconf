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
				editor.line-number = "relative";
				editor.cursor-shape.insert = "bar";
			};
		};
	};
}