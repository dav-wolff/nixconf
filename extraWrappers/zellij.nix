{ lib, wlib, ... }:

wlib.wrapModule ({ config, ... }: {
	options = {
		settings = lib.mkOption {
			type = lib.types.str;
			description = ''
				Settings in KDL format
				See <https://zellij.dev/documentation/configuration.html>
			'';
		};
	};
	
	config = {
		package = lib.mkDefault config.pkgs.zellij;
		env = {
			ZELLIJ_CONFIG_FILE = builtins.toString (config.pkgs.writeText "zellij.kdl" config.settings);
		};
	};
})
