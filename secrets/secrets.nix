let
	keys = import ../public-keys.nix;
in {
	"hotspotPassword.age".publicKeys = [keys.hostKeys.shuttle];
	"vaultwardenKey.age".publicKeys = [keys.hostKeys.shuttle];
	# nix shell pkgs#apacheHttpd
	# htpasswd -c /path/to/password.age dav
	"navidromePassword.age".publicKeys = [keys.hostKeys.shuttle];
	"owntracksPassword.age".publicKeys = [keys.hostKeys.shuttle];
	"changedetectionPassword.age".publicKeys = [keys.hostKeys.shuttle];
	"dkim.rsa.age".publicKeys = [keys.hostKeys.shuttle]; # openssl genrsa -out /path/to/dkim.rsa.age 2048
	"opensmtpdPassword.age".publicKeys = [keys.hostKeys.shuttle];
	"keys.gpg.age".publicKeys = keys.allHostKeys; # gpg --export-secret-keys --export-options backup --output keys.gpg
}
