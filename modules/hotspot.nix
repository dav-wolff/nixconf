{
	services.create_ap = {
		enable = true;
		settings = {
			INTERNET_IFACE = "enp2s0f5";
			WIFI_IFACE = "wlp3s0";
			SSID = "shuttle";
			PASSPHRASE = (import ../secrets.nix).wifiHotspotPassword;
		};
	};
}
