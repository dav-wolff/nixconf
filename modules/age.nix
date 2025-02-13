{ config, lib, pkgs, ... }:

let
	cfg = config.age;
in {
	# extend agenix functionality
	options.age = with lib; {
		derivedSecrets = mkOption {
			default = {};
			type = types.attrsOf (types.submodule ({config, ...}: {
				options = {
					name = mkOption {
						type = types.str;
						default = config._module.args.name;
					};
					secret = mkOption {
						type = types.str;
					};
					owner = mkOption {
						type = types.nullOr types.str;
						default = null;
					};
					script = mkOption {
						type = types.str;
					};
					inputs = mkOption {
						type = types.listOf types.package;
						default = [];
					};
					path = mkOption {
						type = types.str;
						default = "${cfg.secretsDir}/${config.name}";
					};
				};
			}));
		};
	};
	
	config = lib.mkMerge [
		{
			environment.systemPackages = [
				pkgs.agenix
			];
		}
		
		(lib.mkIf (cfg.derivedSecrets != {}) {
			system.activationScripts.agenixDerivedSecrets = let
				deriveSecret = options: let
					script = pkgs.writeShellApplication {
						name = "age-derive-secret-${options.name}";
						runtimeInputs = options.inputs;
						text = "secret=${options.secret}\n${options.script}";
					};
				in ''
					echo "deriving secret '${options.name}' from '${options.secret}' to '${options.path}'"
					touch ${options.path}
					chmod 400 ${options.path}
					${lib.getExe script} > ${options.path}
					${lib.optionalString (options.owner != null) "chown ${options.owner} ${options.path}"}
				'';
			in {
				text = builtins.concatStringsSep "\n" (
					["echo '[agenix] deriving secrets...'"]
					++ (map deriveSecret (builtins.attrValues cfg.derivedSecrets))
				);
				deps = ["agenix"];
			};
		})
		
		(lib.mkIf (config.age.secrets != {} && !config.services.openssh.enable) {
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
		})
	];
}
