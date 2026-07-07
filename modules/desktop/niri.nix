{ config, lib, pkgs, ... }:

let
	cfg = config.modules.niri;
in {
	options.modules.niri.enable = lib.mkEnableOption "niri";
	
	config = lib.mkIf cfg.enable {
		programs.niri.enable = true;
		environment.etc."niri/config.kdl" = {
			source = pkgs.writeText "niri-config.kdl" (builtins.readFile ./niri.kdl);
			mode = "644";
		};
		
		# programs.niri.enable enables services.gnome.gnome-keyring
		# and services.gnome.gnome-keyring enables services.gnome.gcr-ssh-agent
		# which conflicts with programs.ssh.startAgent
		services.gnome.gcr-ssh-agent.enable = false;
		
		services.power-profiles-daemon.enable = true; # already enabled without this, but not sure by what, maybe KDE?
		services.playerctld.enable = true;
		
		environment.systemPackages = with pkgs; [
			fuzzel
			mako
			xwayland-satellite
			swaylock
			swayosd
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
					mixxc
				];
				mako.wantedBy = ["niri.service"];
				
				# service is not needed as niri now handles spawning xwayland-satellite on demand
				xwayland-satellite.enable = false;
				
				wallpaper = let
					wallpapers = map pkgs.fetchurl [
						{
							url = "https://w.wallhaven.cc/full/7j/wallhaven-7jgyre.jpg";
							hash = "sha256-1psemyS4GqYddmvIplS7o7xGQmcu505Ujb/zy/CQY9Y=";
						}
						{
							url = "https://w.wallhaven.cc/full/po/wallhaven-po7l8j.jpg";
							hash = "sha256-xXkQ7jgO5c22Gw6ch/Y8uc7sC6SMlEirDOPlDHtyZH0=";
						}
						{
							url = "https://w.wallhaven.cc/full/yq/wallhaven-yqg6r7.jpg";
							hash = "sha256-RI/KERuKYPLcIpjawRsElocoOtEcZy6UR/D4dqoLqSg=";
						}
						{
							url = "https://w.wallhaven.cc/full/ly/wallhaven-lyz3d2.png";
							hash = "sha256-6d19cynu25xCQJFS+TTj1ZOVyZPe5FlYViWRT2sKqUY=";
						}
						{
							url = "https://w.wallhaven.cc/full/po/wallhaven-po99ee.jpg";
							hash = "sha256-vDDLKopwlSWJOV+YmY1G3r0HJ1sQ1Vk6V0Qa1ooQQZE=";
						}
						{
							url = "https://w.wallhaven.cc/full/d8/wallhaven-d8386j.png";
							hash = "sha256-kjlrWCnKGLXxkkeu0QjVDHc/3HR79lMkqgRT1k9gbkk=";
						}
						{
							url = "https://w.wallhaven.cc/full/k8/wallhaven-k82jl6.png";
							hash = "sha256-AEOr+QD9scbnxJooN+m6k63Thtf7CxrELL3/AaO6BQQ=";
						}
						{
							url = "https://w.wallhaven.cc/full/xe/wallhaven-xeez5l.jpg";
							hash = "sha256-/XGDkWcCc9ODkkQk6HRi6hxZcj5QNL9QpK+GoAt+QhE=";
						}
						{
							url = "https://w.wallhaven.cc/full/vp/wallhaven-vpo5x3.jpg";
							hash = "sha256-5jmGwtZ36sSOqs1kwwVjVPd5HuF3IgWgorx8PoFmkhU=";
						}
						{
							url = "https://w.wallhaven.cc/full/8g/wallhaven-8gkzoy.jpg";
							hash = "sha256-PeovFTxfeCGK9WkjL/WI2c+5FVRl06/PUAwcCr2XmWk=";
						}
					];
					wallpapersBash = lib.concatMapStringsSep " " (wallpaper: ''"${wallpaper}"'') wallpapers;
					wallpapersLength = builtins.length wallpapers;
					# source: https://www.reddit.com/r/NixOS/comments/1mpwpvp/i_made_some_nix_wallpapers/
					overlayWallpaper = pkgs.fetchurl {
						url = "https://drive.usercontent.google.com/download?id=1IEzCRf8CVq0Kx4ba8FEx_gyyfCRH6VnD&export=download";
						hash = "sha256-ktvxacXcZdGjbJ0VF260K2NFDELEmxDCqbhecJI9ioM=";
					};
					chooseWallpaper = pkgs.writeShellScript "chooseWallpaper" ''
						# choose random wallpaper based on current week
						WALLPAPERS=(${wallpapersBash})
						RANDOM=$(date +%Y%V)
						INDEX=$((RANDOM % ${toString wallpapersLength}))
						WALLPAPER=''${WALLPAPERS[$INDEX]}
						echo Selected wallpaper at $WALLPAPER
						
						${lib.getExe pkgs.simplewall} \
							$WALLPAPER \
							-- ${overlayWallpaper} --namespace overlay-wallpaper --format png
					'';
				in {
					wantedBy = ["niri.service"];
					requisite = ["graphical-session.target"];
					partOf = ["graphical-session.target"];
					after = ["graphical-session.target"];
					serviceConfig = {
						ExecStart = "${chooseWallpaper}";
						Restart = "on-failure";
					};
				};
				
				swayosd = let
					config = {
						server = {
							show_percentage = true;
							top_margin = 0.08;
						};
					};
					
					toml = pkgs.formats.toml {};
					configFile = toml.generate "swayosd.toml" config;
					style = pkgs.writeText "swayosd.css" (builtins.readFile ./swayosd.css);
				in {
					wantedBy = ["niri.service"];
					partOf = ["graphical-session.target"];
					after = ["graphical-session.target"];
					
					serviceConfig = {
						ExecStart = "${pkgs.swayosd}/bin/swayosd-server --config ${configFile} --style ${style}";
						Restart = "on-failure";
					};
				};
			};
		};
	};
}
