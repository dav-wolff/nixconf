{ pkgs, vault, ... }:

let
	inherit (pkgs) system;
	
	vaultConfigured = vault.packages.${system}.default.withAttrs {
		port = 80;
	};
	
	vault-wrapped = pkgs.writeShellScriptBin "vault-wrapped" ''
		export VAULT_AUTH_KEY=$STATE_DIRECTORY/auth.key
		export VAULT_DB_FILE=$STATE_DIRECTORY/vault.db
		export VAULT_FILES_LOCATION=$STATE_DIRECTORY/files
		${vaultConfigured}/bin/vault
	'';
in
{
	networking.firewall.allowedTCPPorts = [80];
	
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
			User="vault";
			Group="vault";
			StateDirectory = "vault";
			StateDirectoryMode ="0700";
			AmbientCapabilities="CAP_NET_BIND_SERVICE";
		};
	};
}
