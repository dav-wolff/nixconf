{ config, lib, pkgs, ... }:

let
	cfg = config.modules.vault;
	inherit (config) ports;
	
	vaultConfigured = pkgs.vault-rs.override {
		port = ports.vault;
	};
	
	vault-wrapped = pkgs.writeShellScriptBin "vault-wrapped" ''
		export VAULT_AUTH_KEY=$STATE_DIRECTORY/auth.key
		export VAULT_DB_FILE=$STATE_DIRECTORY/vault.db
		export VAULT_FILES_LOCATION=$STATE_DIRECTORY/files
		${vaultConfigured}/bin/vault
	'';
in {
	options.modules.vault = {
		enable = lib.mkEnableOption "vault";
	};
	
	config = lib.mkIf cfg.enable {
		modules.webServer.hosts.vault = {
			auth = false;
			proxyPort = ports.vault;
			maxBodySize = "10000M";
		};
		
		users.users.vault = {
			group = "vault";
			isSystemUser = true;
		};
		
		users.groups.vault = {};
		
		systemd.services.vault = {
			description = "Vault";
			wantedBy = ["multi-user.target"];
			
			serviceConfig = {
				ExecStart = "${vault-wrapped}/bin/vault-wrapped";
				User ="vault";
				Group ="vault";
				StateDirectory = "vault";
				StateDirectoryMode = "0700";
				AmbientCapabilities = "CAP_NET_BIND_SERVICE";
			};
		};
	};
}
