let
	keys = import ../public-keys.nix;
in {
	"hotspotPassword.age".publicKeys = keys.allHostKeys;
}
