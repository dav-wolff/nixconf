{ wrapPackage
, writeText
, zellij
}:

wrapPackage zellij {
	env = {
		ZELLIJ_CONFIG_FILE = writeText "zellij-config" (builtins.readFile ./zellij.kdl);
	};
}
