{
	modules = {
		ssh.server = {
			enable = true;
			public = true;
		};
		
		webServer = {
			enable = true;
			baseDomain = "min.dav.dev";
		};
		
		solitaire.web = true;
	};
}
