{ config, lib, pkgs, ... }:

let
	cfg = config.modules.niri;
in {
	options.modules.niri.enable = lib.mkEnableOption "niri";
	
	config = lib.mkIf cfg.enable {
		programs.niri.enable = true;
		environment.etc."niri/config.kdl" = {
			source = pkgs.writeText "niri-config.kdl" (builtins.readFile ./niri.kdl);
		};
		
		services.power-profiles-daemon.enable = true; # already enabled without this, but not sure by what, maybe KDE?
		services.playerctld.enable = true;
		
		environment.systemPackages = with pkgs; [
			fuzzel
			mako
			xwayland-satellite
			swaybg
			swaylock
		];
		
		programs.waybar = let
			power-menu = pkgs.writeText "waybar-power-menu.xml" (builtins.readFile ./waybar-power-menu.xml);
			config = pkgs.writeText "waybar-config.jsonc" (builtins.replaceStrings
				["@POWER_MENU@"]
				["${power-menu}"]
				(builtins.readFile ./waybar.jsonc));
			style = pkgs.writeText "waybar-style.css" (builtins.readFile ./waybar.css);
			waybarWrapped = (pkgs.wrapPackage pkgs.waybar {
				args = ["--config" config "--style" style];
				replaceDerivationInFiles = true;
			});
		in {
			enable = true;
			package = waybarWrapped;
			systemd.target = "niri.service";
		};
		
		systemd = {
			packages = with pkgs; [
				pkgs.mako
				xwayland-satellite
			];
			user.services = {
				waybar.path = with pkgs; [
					niri
					(mixxc.override {enableX11 = false;})
				];
				mako.wantedBy = ["niri.service"];
				xwayland-satellite.wantedBy = ["niri.service"];
				wallpaper = let
					wallpaper = pkgs.fetchurl {
						url = "https://w.wallhaven.cc/full/7j/wallhaven-7jgyre.jpg";
						hash = "sha256-1psemyS4GqYddmvIplS7o7xGQmcu505Ujb/zy/CQY9Y=";
					};
				in {
					wantedBy = ["niri.service"];
					requisite = ["graphical-session.target"];
					partOf = ["graphical-session.target"];
					after = ["graphical-session.target"];
					serviceConfig = {
						ExecStart = "${lib.getExe pkgs.swaybg} -i ${wallpaper}";
						Restart = "on-failure";
					};
				};
			};
		};
	};
}
