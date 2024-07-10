{ config, pkgs, ... }:

let
	gpg = config.programs.gnupg.package;
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
	
	system.activationScripts.importGpgKeys = let
		setupGpg = pkgs.writeShellApplication {
			name = "setupGpg";
			runtimeInputs = [gpg];
			text = ''
				echo "setting up gpg keys..."
				gpg --batch --import ${config.age.secrets.gpgKeys.path}
				gpg --with-colons --fingerprint \
					| sed -r -n 's/^fpr:+([0-9A-F]+):$/\1:6:/p' \
					| gpg --import-ownertrust
			'';
		};
	in {
		deps = ["agenix"];
		text = ''
			export GNUPGHOME=${gnupgHome}
			rm -r $GNUPGHOME
			mkdir -p $GNUPGHOME
			chown dav $GNUPGHOME
			chmod 700 $GNUPGHOME
			${pkgs.su}/bin/su dav -c ${setupGpg}/bin/setupGpg
		'';
	};
}
