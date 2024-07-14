{ config, pkgs, ... }:

let
	gnupgHome = "/var/lib/gnupg-home";
in {
	age.secrets = {
		gpgKeys = {
			file = ../secrets/keys.gpg.age;
			owner = "dav";
		};
	};
	
	environment.sessionVariables = {
		GNUPGHOME = gnupgHome;
	};
	
	programs.gnupg = {
		agent = {
			enable = true;
			pinentryPackage = pkgs.pinentry-tty;
		};
	};
	
	system.activationScripts.setupGnupgHome = {
		text = ''
			rm -rf ${gnupgHome}
			mkdir -p ${gnupgHome}
			chown dav ${gnupgHome}
			chmod 700 ${gnupgHome}
		'';
	};
	
	system.userActivationScripts.importGpgKeys = {
		text = let
			gpg = "${config.programs.gnupg.package}/bin/gpg";
		in ''
			echo "setting up gpg keys..."
			export GNUPGHOME=${gnupgHome}
				${gpg} --batch --import ${config.age.secrets.gpgKeys.path}
				${gpg} --with-colons --fingerprint \
					| sed -r -n 's/^fpr:+([0-9A-F]+):$/\1:6:/p' \
					| ${gpg} --import-ownertrust
		'';
	};
}
