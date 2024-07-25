{ buildNpmPackage
, fetchFromGitHub
}:

buildNpmPackage rec {
	pname = "owntracks-frontend";
	version = "2.15.3";
	
	src = fetchFromGitHub {
		owner = "owntracks";
		repo = "frontend";
		rev = "v${version}";
		hash = "sha256-omNsCD6sPwPrC+PdyftGDUeZA8nOHkHkRHC+oHFC0eM=";
	};
	
	npmDepsHash = "sha256-sZkOvffpRoUTbIXpskuVSbX4+k1jiwIbqW4ckBwnEHM=";
	
	installPhase = ''
		runHook preInstall
		
		cp -r dist $out
		
		runHook postInstall
	'';
}
