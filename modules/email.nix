{ config, lib, pkgs, ... }:

let
	cfg = config.modules.email;
	inherit (pkgs) unindent;
in {
	options.modules.email = {
		enable = lib.mkEnableOption "email";
		port = lib.mkOption {
			type = lib.types.port;
			default = 4323;
		};
		domain = lib.mkOption {
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
		
		services.opensmtpd = {
			enable = true;
			extraServerArgs = ["-P mda"];
			serverConfiguration = let
				senders = lib.concatMapStringsSep "," (sender: "\"${sender}@${cfg.domain}\"") cfg.senders;
				filter-dkimsign = "${pkgs.opensmtpd-filter-dkimsign}/libexec/opensmtpd/filter-dkimsign";
				rsaKey = config.age.secrets.dkimRsaKey.path;
			in unindent ''
				table "senders" { ${senders} }
				filter "dkim-sign-rsa" proc-exec "${filter-dkimsign} -a rsa-sha256 -d dav.dev -s rsa -k ${rsaKey}"
				action "send" relay helo "${cfg.domain}"
				match mail-from <"senders"> for any action "send"
				listen on lo port ${toString cfg.port} filter "dkim-sign-rsa"
			'';
		};
	};
}
