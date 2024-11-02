{ config, lib, pkgs, ... }:

let
	cfg = config.modules.games;
in {
	options.modules.games = {
		enable = lib.mkEnableOption "games";
		minecraftServer.enable = lib.mkEnableOption "minecraftServer";
	};
	
	config = lib.mkMerge [
		(lib.mkIf cfg.enable {
			environment.systemPackages = with pkgs; [
				prismlauncher
			];
			
			programs.steam.enable = true;
		})
		
		(lib.mkIf (cfg.enable && cfg.minecraftServer.enable) {
			services.minecraft-servers = {
				enable = true;
				eula = true;
				openFirewall = true;
				managementSystem = {
					tmux.enable = false;
					systemd-socket.enable = true;
				};
				servers.smp = {
					enable = true;
					autoStart = false;
					package = pkgs.paperServers.paper-1_21_1;
					jvmOpts = "-Xms6G -Xmx6G";
					serverProperties = {
						white-list = true;
						view-distance = 32;
						motd = "Minecraft SMP ❤";
					};
				};
			};
		})
	];
}
