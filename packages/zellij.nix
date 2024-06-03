{ runCommand
, makeWrapper
, zellij
}:

let
	configFile = ./zellij.kdl;
in
	runCommand zellij.name {
		inherit (zellij) pname version meta;
		nativeBuildInputs = [makeWrapper];
	} ''
		cp -rs --no-preserve=mode,ownership ${zellij} $out
		wrapProgram "$out/bin/zellij" --set ZELLIJ_CONFIG_FILE "${configFile}"
	''
