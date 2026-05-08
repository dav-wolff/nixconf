{ pkgs, ... }:

{
	# Fix for dirty frag exploit,
	# according to: https://discourse.nixos.org/t/is-nixos-affected-by-dirty-frag/77479/2?u=dav-w
	boot.extraModprobeConfig = ''
		install esp4 ${pkgs.coreutils}/bin/false
		install esp6 ${pkgs.coreutils}/bin/false
		install rxrpc ${pkgs.coreutils}/bin/false
	'';
	boot.blacklistedKernelModules = [
		"esp4"
		"esp6"
		"rxrpc"
	];
}
