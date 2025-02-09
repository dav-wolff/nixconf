{ pkgs, ... }:

{
	systemd.services.numLockOnTty = {
		wantedBy = [ "multi-user.target" ];
		serviceConfig = {
			ExecStart = pkgs.writeShellScript "numLockOnTty" ''
				for tty in /dev/tty{1..6}; do
						${pkgs.kbd}/bin/setleds -D +num < "$tty";
				done
			'';
		};
	};
}
