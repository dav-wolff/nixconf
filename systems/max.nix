{
	modules = {
		bootLoader.enable = true;
		networking.enable = true;
		desktop.enable = true;
		nvidia.enable = true;
		
		games = {
			enable = true;
			minecraftServer.enable = true;
		};
		
		immich = {
			remoteMachineLearning = true;
			port = 8333;
		};
	};
}
