{ config, lib, pkgs, ... }:

let
	cfg = config.modules.email;
	inherit (config) ports;
	inherit (pkgs) unindent;
in {
	options.modules.email = {
		enable = lib.mkEnableOption "email";
		domain = lib.mkOption {
			type = lib.types.str;
		};
		cert = lib.mkOption {
			type = lib.types.str;
		};
		senders = lib.mkOption {
			type = lib.types.listOf lib.types.str;
			default = [];
		};
	};
	
	config = lib.mkIf cfg.enable {
		age.secrets.dkimRsaKey = {
			file = ../secrets/dkim.rsa.age;
			owner = "smtpd";
		};
		
		age.secrets.opensmtpdPassword = {
			file = ../secrets/opensmtpdPassword.age;
		};
		
		age.derivedSecrets.opensmtpdCreds = {
			secret = config.age.secrets.opensmtpdPassword.path;
			owner = "smtpd";
			inputs = with pkgs; [opensmtpd];
			script = ''
				# smtpctl requires setgid which is provided by the wrapper
				encryptedPassword=$(${config.security.wrapperDir}/smtpctl encrypt < $secret)
				echo "mailuser $encryptedPassword"
			'';
		};
		
		modules.acme = {
			enable = true;
			users = ["smtpd"];
		};
		
		# because opensmtpd requires the certificate to be owned by root LoadCredential is necessary
		# https://github.com/OpenSMTPD/OpenSMTPD/issues/1142
		# https://nixos.org/manual/nixos/stable/#module-security-acme-root-owned
		# TODO: amend to work with acmed
		# security.acme.certs.${cfg.domain}.postRun = ''
		# 	systemctl restart opensmtpd
		# '';
		
		systemd.services.opensmtpd = {
			after = ["acmed.service"];
			wants = ["acmed.service"];
			serviceConfig.LoadCredential = let
				cert = config.modules.acme.certs.${cfg.cert};
			in [
				"cert.pem:${cert.certFile}"
				"key.pem:${cert.privateKeyFile}"
			];
		};
		
		services.opensmtpd = {
			enable = true;
			extraServerArgs = ["-P mda"];
			serverConfiguration = let
				senders = lib.concatMapStringsSep "," (sender: "\"${sender}@${cfg.domain}\"") cfg.senders;
				filter-dkimsign = "${pkgs.opensmtpd-filter-dkimsign}/libexec/opensmtpd/filter-dkimsign";
				creds = config.age.derivedSecrets.opensmtpdCreds.path;
				rsaKey = config.age.secrets.dkimRsaKey.path;
				credsDir = "/run/credentials/opensmtpd.service";
			in unindent ''
				table "creds" "${creds}"
				table "senders" { ${senders} }
				
				pki "cert" cert "${credsDir}/cert.pem"
				pki "cert" key "${credsDir}/key.pem"
				
				filter "dkim-sign-rsa" proc-exec "${filter-dkimsign} -a rsa-sha256 -d dav.dev -s rsa -k ${rsaKey}"
				
				action "send" relay helo "${cfg.domain}"
				match mail-from <"senders"> for any action "send"
				
				listen on lo port ${toString ports.email} filter "dkim-sign-rsa" tls pki "cert" auth <"creds">
			'';
		};
	};
}
