{ pkgs, wrapperModules, ... }:

wrapperModules.nushell.apply (let
	inherit (pkgs) lib;
	
	includeScripts = pkgs.runCommandLocal "nushell-scripts" {
		buildInputs = with pkgs; [
			zoxide
			fzf
			jujutsu
		];
	} ''
		mkdir -p $out
		zoxide init nushell --cmd cd > $out/zoxide.nu
		fzf --nushell > $out/fzf.nu
		jj util completion nushell > $out/completions-jj.nu
	'';
	
	nushellPlugins = pkgs.runCommand "nushell-plugins" {} ''
		${lib.getExe pkgs.nushell} --plugin-config $out -c "
			plugin add ${lib.getExe pkgs.nushellPlugins.desktop_notifications}
			plugin add ${lib.getExe pkgs.nushellPlugins.port_extension}
		"
	'';
in {
	inherit pkgs;
	
	"config.nu".content = builtins.readFile ./nushell.nu;
	
	flags = {
		"--plugin-config" = "${nushellPlugins}";
		"--include-path" = "${includeScripts}";
	};
	
	extraPackages = with pkgs; [
		zoxide
		fzf
	];
})
