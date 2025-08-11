{ wrapPackage
, jujutsu
, formats
}:

let
	config = {
		user = {
			name = "David Wolff";
			email = "david@dav.dev";
		};
		ui = {
			default-command = "log";
			diff-editor = ":builtin";
			pager = "less -FRX";
		};
		signing = {
			behavior = "drop";
			backend = "gpg";
			backends.gpg.allow-expired-keys = false;
		};
		git = {
			sign-on-push = true;
		};
	};
	
	toml = formats.toml {};
	configFile = toml.generate "jujutsu-config" config;
in wrapPackage jujutsu {
	env = {
		JJ_CONFIG = configFile;
	};
}
