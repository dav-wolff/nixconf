{ lib, config, pkgs , ... }:

let
	packages = builtins.filter (pkg: pkg ? version) config.environment.systemPackages;
	
	packageInfos = lib.unique (map (pkg:
		let
			inherit (pkg) version;
			length = builtins.stringLength pkg.name - builtins.stringLength version - 1;
			pname = lib.substring 0 length pkg.name;
		in
			"${pname} ${version}"
	) packages);
	
	listPackages = pkgs.writeShellScriptBin "pkgs" (lib.concatMapStrings (pkgInfo: ''
		echo "${pkgInfo}"
	'') packageInfos);
in {
	environment.systemPackages = [
		listPackages
	];
}
