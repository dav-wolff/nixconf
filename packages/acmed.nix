{
	lib,
	stdenv,
	fetchFromGitHub,
	rustPlatform,
	rustc,
	cargo,
	pkg-config,
	openssl,
}:

let
	pname = "acmed";
	version = "0.25.0";
	src = fetchFromGitHub {
		owner = "breard-r";
		repo = "acmed";
		rev = "v${version}";
		hash = "sha256-QEQUzV1S08x7EyM2REw1U3gNmcYCyFc095fVGwyruuo=";
	};
	cargoDeps = rustPlatform.importCargoLock {
		lockFile = "${src}/Cargo.lock";
	};
in stdenv.mkDerivation {
	inherit pname version src cargoDeps;
	
	outputs = ["out" "man"];
	
	nativeBuildInputs = [
		rustPlatform.cargoSetupHook
		rustc
		cargo
		pkg-config
		openssl
	];
	
	installPhase = ''
		make BINDIR=$out/bin DATAROOTDIR=$man/share SYSCONFDIR=$out/etc VARLIBDIR=./var/lib install
	'';
	
	meta = {
		description = "ACME (RFC 8555) client daemon";
		mainProgram = "acmed";
		homepage = "https://github.com/breard-r/acmed";
		changelog = "https://github.com/breard-r/acmed/blob/v${version}/CHANGELOG.md";
		license = with lib.licenses; [mit asl20];
		maintainers = with lib.maintainers; [dav-wolff];
	};
}
