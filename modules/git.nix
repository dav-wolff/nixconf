{
	programs.git = {
		enable = true;
		config = {
			user.name = "David Wolff";
			user.email = "david@dav.dev";
			init.defaultBranch = "master";
			pull.ff = "only";
			alias = {
				c = "commit -m";
				co = "checkout";
				s = "status";
				a = "add";
				l = "log --oneline";
				pushf = "push --force-with-lease";
			};
		};
	};
}
