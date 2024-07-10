{ config, lib, pkgs, ... }:

{
	config = {
		environment.systemPackages = [
			pkgs.agenix
		];
	} // lib.mkIf (config.age.secrets != {} && !config.services.openssh.enable) {
		# If openssh is not enabled, it won't generate its keys.
		# However, they're still required for agenix to work.
		system.activationScripts.generateSSHKeys = {
			# from nixpkgs/nixos/modules/services/networking/ssh/sshd.nix
			text = with lib; flip concatMapStrings config.services.openssh.hostKeys (k: ''
				if ! [ -s "${k.path}" ]; then
						if ! [ -h "${k.path}" ]; then
								rm -f "${k.path}"
						fi
						mkdir -m 0755 -p "$(dirname '${k.path}')"
						${pkgs.openssh}/bin/ssh-keygen \
							-t "${k.type}" \
							${optionalString (k ? bits) "-b ${toString k.bits}"} \
							${optionalString (k ? rounds) "-a ${toString k.rounds}"} \
							${optionalString (k ? comment) "-C '${k.comment}'"} \
							${optionalString (k ? openSSHFormat && k.openSSHFormat) "-o"} \
							-f "${k.path}" \
							-N ""
				fi
			'');
		};
		
		system.activationScripts.agenixInstall.deps = ["generateSSHKeys"];
		
		# agenix only sets identityPaths by default if openssh is enabled
		# from agenix/modules/age.nix
		age.identityPaths = with lib; map (e: e.path) (filter (e: e.type == "rsa" || e.type == "ed25519") config.services.openssh.hostKeys);
	};
}
