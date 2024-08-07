let
	keys = import ../public-keys.nix;
in {
	"hotspotPassword.age".publicKeys = [keys.hostKeys.shuttle];
	"vaultwardenKey.age".publicKeys = [keys.hostKeys.shuttle];
	"owntracksPassword.age".publicKeys = [keys.hostKeys.shuttle]; # htpasswd -c /path/to/owntracksPassword.age dav
	"keys.gpg.age".publicKeys = keys.allHostKeys; # gpg --export-secret-keys --export-options backup --output keys.gpg
}
