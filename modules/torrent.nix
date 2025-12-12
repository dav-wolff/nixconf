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
			proxyPort = ports.qbittorrent;
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
		
		modules.vpn.enable = true;
		modules.firewall.forceVpn.members = [config.services.qbittorrent.user];
	};
}
