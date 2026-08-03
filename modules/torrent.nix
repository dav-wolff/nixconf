{ config, lib, ... }:

let
	cfg = config.modules.torrent;
	inherit (config) ports;
in {
	options.modules.torrent = {
		enable = lib.mkEnableOption "torrent";
		volume = lib.mkOption {
			type = lib.types.str;
		};
	};
	
	config = lib.mkIf cfg.enable {
		modules.webServer.hosts.torrent = {
			proxyPort = ports.qui;
			authing.allow_group = "torrent";
		};
		
		services.qbittorrent = {
			enable = true;
			webuiPort = ports.qbittorrent;
			openFirewall = false;
			serverConfig = {
				LegalNotice.Accepted = true;
				BitTorrent.Session = {
					Interface = config.modules.vpn.interface;
					InterfaceName = config.modules.vpn.interface;
					AnonymousModeEnabled = true;
					DefaultSavePath = "${cfg.volume}/done";
					TempPathEnabled = true;
					TempPath = "${cfg.volume}/download";
					MaxActiveDownloads = 10;
					MaxActiveUploads = 5;
					MaxActiveTorrents = 10;
					LSDEnabled = false;
				};
				Preferences = {
					General = {
						StatusbarExternalIPDisplayed = true;
					};
					WebUI.LocalHostAuth = false;
				};
			};
		};
		
		age.secrets.quiSecret = {
			file = ../secrets/quiSecret.age;
		};
		
		services.qui = {
			enable = true;
			# NixOS module expects this option
			secretFile = config.age.secrets.quiSecret.path;
			settings = {
				port = ports.qui;
				checkForUpdates = false;
				authDisabled = true;
				authDisabledAllowedCIDRs = "127.0.0.1";
				# referring to disabling auth, not a bad idea as auth is handled by authing
				I_ACKNOWLEDGE_THIS_IS_A_BAD_IDEA = true;
			};
		};
		
		modules.vpn.enable = true;
		modules.firewall.forceVpn.members = [config.services.qbittorrent.user config.services.qui.user];
	};
}
