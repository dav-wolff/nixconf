{ pkgs }:

let
	configFile = ./zellij.kdl;
	
	zellij = pkgs.zellij;
in
	pkgs.runCommand zellij.name {
		inherit (zellij) pname version meta;
		nativeBuildInputs = [pkgs.makeWrapper];
	} ''
		cp -rs --no-preserve=mode,ownership ${zellij} $out
		wrapProgram "$out/bin/zellij" --set ZELLIJ_CONFIG_FILE "${configFile}"
	''
