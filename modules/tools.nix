{ pkgs, ... }:

{
	environment.systemPackages = with pkgs; [
		rbw
		backy
		ndent
		journal
		ncdu
		xh
		dysk
	];
}
