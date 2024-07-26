pkgs:

pkgs.writeShellApplication {
	name = "update";
	runtimeInputs = [pkgs.jq pkgs.diffutils];
	
	text = ''
		description=$(nix flake info --json 2> /dev/null | jq -r .description || true)
		
		if [ "$description" != "dav's NixOS configurations" ]; then
			echo "This script should only be run inside nixconf" >&2
			exit 1
		fi
		
		git_status=$(git status --short)
		
		prev_pkgs=$(mktemp)
		pkgs > "$prev_pkgs"
		nix flake update
		sudo nixos-rebuild test
		new_pkgs=$(mktemp)
		pkgs > "$new_pkgs"
		
		diff=$(mktemp)
		diff "$prev_pkgs" "$new_pkgs" --side-by-side --suppress-common-lines > "$diff" || true
		echo "Removed packages:"
		sed -r -n 's/^(\S+)\s(\S+)\s*<$/\t\1 \2/p' "$diff"
		echo "Updated packages:"
		sed -r -n 's/^(\S+)\s(\S+)\s*\|\s*\S+\s(\S+).*$/\t\1 \2 -> \3/p' "$diff"
		echo "New packages:"
		sed -r -n 's/^\s*>\s*(\S+)\s(\S+)$/\t\1 \2/p' "$diff"
		
		if [ "$git_status" == "" ]; then
			git commit -a -m "Update NixOS"
		else
			echo "Git tree was dirty, not committing..."
		fi
	'';
}
