{ config, lib, pkgs, ... }:

let
	cfg = config.modules.ssh;
	inherit (pkgs) unindent;
	publicKeys = import ../public-keys.nix;
	knownHosts = builtins.mapAttrs (name: publicKey: {
		inherit publicKey;
	}) publicKeys.sshKnownHosts;
in {
	options.modules.ssh.server = {
		enable = lib.mkEnableOption "sshServer";
		openPort = lib.mkOption {
			type = lib.types.bool;
			default = false;
		};
	};
	
	config = lib.mkMerge [{
			programs.ssh = {
				startAgent = true;
				inherit knownHosts;
				extraConfig = let
					proxyCommand = pkgs.writeShellScript "proxytunnel" (unindent ''
						echo "-----------------------------" > /dev/tty
						echo "| Unlocking bitwarden vault |" > /dev/tty
						echo "-----------------------------" > /dev/tty
						
						# Terminal to request password on
						export RBW_TTY="/dev/`ps -p $$ -o tty=`"
						
						PROXYUSER=$(rbw get -f username Auth) \
						PROXYPASS=$(rbw get Auth) \
						proxytunnel -E -p $1:443 -d $1:$2 -C /etc/ssl/certs/ca-certificates.crt
					'');
				in unindent ''
					Host ssh.* git.dav.dev
						ProxyCommand ${proxyCommand} %h %p
						ServerAliveInterval 30
				'';
			};
			
			environment.systemPackages = with pkgs; [
				proxytunnel
			];
		}
		(lib.mkIf cfg.server.enable {
			modules.firewall.localAllowedTCPPorts = lib.mkIf (cfg.server.openPort) [22];
			
			modules.webServer.hosts.ssh = {
				locations."/" = {
					extraConfig = ''
						tunnel_pass localhost:22;
					'';
				};
			};
			
			services.authing.settings = {
				groups = ["ssh"];
				hosts.ssh = {
					host = config.modules.webServer.hosts.ssh.domain;
					allow_group = "ssh";
				};
			};
			
			services.openssh = let
				banner = pkgs.runCommandLocal "ssh-banner.txt" {} ''
					${lib.getExe pkgs.figlet} ${config.networking.hostName} > $out
				'';
			in {
				enable = true;
				openFirewall = false;
				settings = {
					PasswordAuthentication = false;
					KbdInteractiveAuthentication = false;
					Banner = "${banner}";
				};
				inherit knownHosts;
			};
			
			users.users.dav.openssh.authorizedKeys.keys = publicKeys.allUserKeys;
			
			# ssh runs through nginx, so restarting drops the connection
			systemd.services = {
				authing.stopIfChanged = false;
				nginx.restartIfChanged = false;
			};
		})
	];
}
