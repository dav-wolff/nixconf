{ pkgs, wrapperModules, ... }:

wrapperModules.jujutsu.apply {
	inherit pkgs;
	
	settings = {
		user = {
			name = "David Wolff";
			email = "david@dav.dev";
		};
		ui = {
			default-command = "log";
			diff-editor = ":builtin";
			pager = "less -FRX";
			show-cryptographic-signatures = true;
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
}
