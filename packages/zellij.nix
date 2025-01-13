{ wrapPackage
, zellij
}:

wrapPackage zellij {
	env = {
		ZELLIJ_CONFIG_FILE = ./zellij.kdl;
	};
}
