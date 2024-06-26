let
	keys = import ../public-keys.nix;
in {
	"hotspotPassword.age".publicKeys = [keys.hostKeys.shuttle];
	"vaultwardenKey.age".publicKeys = [keys.hostKeys.shuttle];
}
