let
	keys = import ../public-keys.nix;
in {
	"hotspotPassword.age".publicKeys = [keys.hostKeys.shuttle];
	"vaultwardenKey.age".publicKeys = [keys.hostKeys.shuttle];
	# nix shell pkgs#apacheHttpd
	# htpasswd -c /path/to/password.age dav
	"dkim.rsa.age".publicKeys = [keys.hostKeys.shuttle]; # openssl genrsa -out /path/to/dkim.rsa.age 2048
	"opensmtpdPassword.age".publicKeys = [keys.hostKeys.shuttle];
	# gpg --full-generate-key
	# ECC sign and encrypt Curve 25519 6m
	# gpg --export-secret-keys --export-options backup --output keys.gpg
	"keys.gpg.age".publicKeys = keys.allHostKeys;
	# nix run pkgs#openssl -- rand -base64 32 > /path/to/key.age
	"autheliaJwtSecret.age".publicKeys = [keys.hostKeys.shuttle];
	"autheliaStorageEncryptionKey.age".publicKeys = [keys.hostKeys.shuttle];
	"autheliaOidcHmac.age".publicKeys = [keys.hostKeys.shuttle];
	"autheliaOidcPrivateKey.age".publicKeys = [keys.hostKeys.shuttle];
	"mealieOidcSecret.age".publicKeys = [keys.hostKeys.shuttle];
	"shuttlePorkbunApiKey.age".publicKeys = [keys.hostKeys.shuttle];
	"shuttlePorkbunApiSecret.age".publicKeys = [keys.hostKeys.shuttle];
	"minPorkbunApiKey.age".publicKeys = [keys.hostKeys.min];
	"minPorkbunApiSecret.age".publicKeys = [keys.hostKeys.min];
	"minSpaceshipApiKey.age".publicKeys = [keys.hostKeys.min];
	"minSpaceshipApiSecret.age".publicKeys = [keys.hostKeys.min];
	"linkyAssetsTar.age".publicKeys = [keys.hostKeys.shuttle keys.hostKeys.min];
	"linkyValuesJson.age".publicKeys = [keys.hostKeys.shuttle keys.hostKeys.min];
	"linkyDomain.age".publicKeys = [keys.hostKeys.shuttle keys.hostKeys.min];
	# 64 randomly generated characters
	"lldapKeySeed.age".publicKeys = [keys.hostKeys.shuttle keys.hostKeys.min];
	"lldapAdminPassword.age".publicKeys = [keys.hostKeys.shuttle keys.hostKeys.min];
	"lldapAutheliaPassword.age".publicKeys = [keys.hostKeys.shuttle keys.hostKeys.min];
}
