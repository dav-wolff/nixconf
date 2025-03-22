{ config, lib, pkgs, ... }:

let
	cfg = config.modules.acme;
in {
	options.modules.acme = with lib; {
		enable = mkEnableOption "acme";
		users = mkOption {
			type = types.listOf types.str;
		};
		spaceshipApiKey = mkOption {
			type = types.nullOr types.path;
			default = null;
		};
		spaceshipApiSecret = mkOption {
			type = types.nullOr types.path;
			default = null;
		};
		porkbunApiKey = mkOption {
			type = types.nullOr types.path;
			default = null;
		};
		porkbunApiSecret = mkOption {
			type = types.nullOr types.path;
			default = null;
		};
		certs = mkOption {
			default = {};
			type = types.attrsOf (types.submodule ({config, ...}: {
				options = {
					name = mkOption {
						type = types.str;
						default = config._module.args.name;
					};
					domain = mkOption {
						type = types.str;
						default = config.name;
					};
					domainFile = mkOption {
						type = types.nullOr types.str;
						default = null;
					};
					certFile = mkOption {
						type = types.path;
					};
					privateKeyFile = mkOption {
						type = types.path;
					};
					provider = mkOption {
						type = types.enum ["spaceship" "porkbun"];
					};
				};
				config = {
					certFile = "/var/lib/acmed/certs/${config.name}_ecdsa-p256.crt.pem";
					privateKeyFile = "/var/lib/acmed/certs/${config.name}_ecdsa-p256.pk.pem";
				};
			}));
		};
	};
	
	config = lib.mkIf cfg.enable (let
		certs = builtins.attrValues cfg.certs;
		
		isSpaceship = cert: cert.provider == "spaceship";
		isPorkbun = cert: cert.provider == "porkbun";
		useSpaceship = lib.any isSpaceship certs;
		usePorkbun = lib.any isPorkbun certs;
		useDomainFile = lib.any (cert: cert.domainFile != null) certs;
		
		acmedConfig = {
			include = ["${pkgs.acmed}/etc/acmed/acmed.toml"];
			
			global = {
				cert_file_mode = 416; # 0o640
				pk_file_mode = 416; # 0o640
				cert_file_group = "acmecert";
				pk_file_group = "acmecert";
			};
			
			account = [{
				name = "main";
				contacts = [{
					mailto = "david@dav.dev";
				}];
			}];
			
			hook = [
				{
					name = "check-files-exist";
					type = ["file-post-create"];
					stdout = "/var/lib/acmed/logs/check-files-exist-out";
					stderr = "/var/lib/acmed/logs/check-files-exist-err";
					cmd = checkFilesExist;
				}
			] ++ lib.optionals useSpaceship [
				{
					name = "spaceship-dns";
					type = ["challenge-dns-01"];
					stdout = "/var/lib/acmed/logs/spaceship-dns-out";
					stderr = "/var/lib/acmed/logs/spaceship-dns-err";
					cmd = spaceshipDns;
					args = [
						"{{ identifier }}"
						"{{ proof }}"
					];
				}
				{
					name = "spaceship-dns-clean";
					type = ["challenge-dns-01-clean"];
					stdout = "/var/lib/acmed/logs/spaceship-dns-clean-out";
					stderr = "/var/lib/acmed/logs/spaceship-dns-clean-err";
					cmd = spaceshipDnsClean;
					args = [
						"{{ identifier }}"
					];
				}
			] ++ lib.optionals usePorkbun [
				{
					name = "porkbun-dns";
					type = ["challenge-dns-01"];
					stdout = "/var/lib/acmed/logs/porkbun-dns-out";
					stderr = "/var/lib/acmed/logs/porkbun-dns-err";
					cmd = porkbunDns;
					args = [
						"{{ identifier }}"
						"{{ proof }}"
					];
				}
				{
					name = "porkbun-dns-clean";
					type = ["challenge-dns-01-clean"];
					stdout = "/var/lib/acmed/logs/porkbun-dns-clean-out";
					stderr = "/var/lib/acmed/logs/porkbun-dns-clean-err";
					cmd = porkbunDnsClean;
					args = [
						"{{ identifier }}"
					];
				}
			];
			
			certificate = map (cert: {
					endpoint = "Let's Encrypt v2 production";
					# use this endpoint for testing
					# endpoint = "Let's Encrypt v2 staging";
					account = "main";
					name = cert.name;
					key_type = "ecdsa_p256";
					hooks = [
						"check-files-exist"
					] ++ lib.optionals (isSpaceship cert) [
						"spaceship-dns"
						"spaceship-dns-clean"
					] ++ lib.optionals (isPorkbun cert) [
						"porkbun-dns"
						"porkbun-dns-clean"
					];
					identifiers = [
						{
							dns = if cert.domainFile == null
								then "${cert.domain}"
								else "@${cert.name}@";
							challenge = "dns-01";
						}
						{
							dns = if cert.domainFile == null
								then "*.${cert.domain}"
								else "*.@${cert.name}@";
							challenge = "dns-01";
						}
					];
			}) certs;
		};
		
		xh = lib.getExe pkgs.xh;
		
		spaceshipDns = pkgs.writeShellScript "spaceship-dns" ''
			set -euxo pipefail
			# https://docs.spaceship.dev/#tag/DNS-records/operation/saveRecords
			# TODO: why is --ignore-stdin necessary? there's no stdin
			${xh} PUT https://spaceship.dev/api/v1/dns/records/$1 \
				--ignore-stdin \
				X-API-Key:@${cfg.spaceshipApiKey} X-API-Secret:@${cfg.spaceshipApiSecret} \
				items[0][type]=TXT items[0][name]=_acme-challenge items[0][ttl]:=60 items[0][value]=$2
		'';
		
		spaceshipDnsClean = pkgs.writeShellScript "spaceship-dns-clean" ''
			set -euxo pipefail
			# https://docs.spaceship.dev/#tag/DNS-records/operation/deleteRecords
			# TODO: why is --ignore-stdin necessary? there's no stdin
			${xh} DELETE https://spaceship.dev/api/v1/dns/records/$1 \
				--ignore-stdin \
				X-API-Key:@${cfg.spaceshipApiKey} X-API-Secret:@${cfg.spaceshipApiSecret} \
				[0][type]=TXT [0][name]=_acme-challenge [0][value]=null # documentation says a value is required
		'';
		
		porkbunDns = pkgs.writeShellScript "porkbun-dns" ''
			set -euxo pipefail
			# https://porkbun.com/api/json/v3/documentation#DNS%20Create%20Record
			# TODO: why is --ignore-stdin necessary? there's no stdin
			${xh} POST https://api.porkbun.com/api/json/v3/dns/create/$1 \
				--ignore-stdin \
				apikey=@${cfg.porkbunApiKey} secretapikey=@${cfg.porkbunApiSecret} type=TXT name=_acme-challenge content=$2
			sleep 30s # allow some time for records to propagate
		'';
		
		porkbunDnsClean = pkgs.writeShellScript "porkbun-dns-clean" ''
			set -euxo pipefail
			# https://porkbun.com/api/json/v3/documentation#DNS%20Delete%20Records%20by%20Domain,%20Subdomain%20and%20Type
			# TODO: why is --ignore-stdin necessary? there's no stdin
			${xh} POST https://api.porkbun.com/api/json/v3/dns/deleteByNameType/$1/TXT/_acme-challenge \
				--ignore-stdin \
				apikey=@${cfg.porkbunApiKey} secretapikey=@${cfg.porkbunApiSecret}
		'';
		
		checkFilesExist = let
			files = lib.concatMapStringsSep " " (cert: "${cert.certFile} ${cert.privateKeyFile}") certs;
		in pkgs.writeShellScript "acmed-check-files-exist" ''
			set -euo pipefail
			for file in ${files}; do
				if [[ ! -f $file ]]; then
					echo "$file does not exist yet."
					exit 0
				fi
			done
			echo "All expected files found."
			systemd-notify --ready
		'';
		
		toml = pkgs.formats.toml {};
		acmedConfigFile = toml.generate "acmed-config" acmedConfig;
	in {
		users.groups.acmecert = {
			members = ["acmed"] ++ cfg.users;
		};
		
		age.derivedSecrets.acmedConfig = lib.mkIf useDomainFile {
			secret = "/dev/null";
			owner = "acmed";
			inputs = with pkgs; [gnused];
			script = let
				replacements = lib.concatMapStrings
					(certificate: ''"s/@${certificate.name}@/$(cat ${certificate.domainFile})/g;"'')
					certs;
			in ''
				sed ${replacements} ${acmedConfigFile}
			'';
		};
		
		users.users.acmed = {
			group = "acmed";
			isSystemUser = true;
		};
		
		users.groups.acmed = {};
		
		systemd.tmpfiles.settings.acmed = let
			acmed = {
				user = "acmed";
				group = "acmed";
			};
			withMode = mode: acmed // {
				inherit mode;
			};
		in {
			# https://github.com/breard-r/acmed/blob/main/contrib/systemd/acmed.tmpfiles
			"/run/acmed".d = withMode "0755";
			"/run/acmed/acmed.pid".f = withMode "0644";
			"/var/lib/acmed".d = withMode "0755";
			"/var/lib/acmed/accounts".d = withMode "0700";
			"/var/lib/acmed/certs".d = withMode "0755";
			"/var/lib/acmed/logs".d = withMode "0755";
		};
		
		systemd.services.acmed = let
			secretConfigFile = config.age.derivedSecrets.acmedConfig.path;
			configFile = if useDomainFile then secretConfigFile else acmedConfigFile;
			
			startScript = pkgs.writeShellScript "acmed-start" ''
				set -euo pipefail
				${checkFilesExist}
				exec ${lib.getExe pkgs.acmed} --foreground --config ${configFile} --pid-file /run/acmed/acmed.pid --log-syslog --log-level debug
			'';
		in {
			# https://github.com/breard-r/acmed/blob/main/contrib/systemd/acmed.service
			description = "ACME client daemon";
			after = ["network.target"];
			documentation = ["man:acmed.toml(5)" "man:acmed(8)" "https://github.com/breard-r/acmed/wiki"];
			serviceConfig = {
				User = "acmed";
				Group = "acmed";
				WorkingDirectory = "/var/lib/acmed";
				RuntimeDirectory = "acmed";
				Type = "notify";
				NotifyAccess = "all";
				ExecStart = startScript;
				TimeoutStartSec = 900; # enough time to renew all certificates
				TimeoutStopSec = 5;
				Restart = "on-failure";
				KillSignal = "SIGINT";
				
				NoNewPrivileges = "yes";
				PrivateDevices = "yes";
				PrivateTmp = "yes";
				# PrivateUsers = "yes"; Doesn't allow changing the group of the certificates
				ProtectClock = "yes";
				ProtectHostname = "yes";
				ProtectKernelTunables = "yes";
				ProtectKernelModules = "yes";
				ProtectKernelLogs = "yes";
				ProtectSystem = "yes";
				ReadWritePaths = "/var/lib/acmed";
				RestrictRealtime = "yes";
				RestrictSUIDSGID = "yes";
				SystemCallFilter = "@system-service";
			};
		};
	});
}
