{ pkgs, ... }:

{
	environment.systemPackages = with pkgs; [
		rbw
		backy
		ndent
		journal
	];
}
