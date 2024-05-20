{ self, name, ... }:

{
	imports = [
		./wsl/wsl-distro.nix
		./wsl/interop.nix
		./fonts.nix
	];
	
	wsl = {
		enable = true;
		automountPath = "/mnt";
		defaultUser = "dav";
		startMenuLaunchers = true;
		
		wslConf.network.hostname = name;
	};
	
	environment.systemPackages = [
		self.packages.x86_64-linux.alacritty
	];
}
