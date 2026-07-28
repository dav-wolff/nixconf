{ pkgs, wrapperModules, ... }:

wrapperModules.nushell.apply (let
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
in {
	inherit pkgs;
	
	"config.nu".content = builtins.readFile ./nushell.nu;
	
	flags = {
		"--include-path" = "${includeScripts}";
	};
	
	extraPackages = with pkgs; [
		zoxide
		fzf
	];
})
