{
	pkgs,
	wrapperModules,
	systemd-services ? {},
	systemd-user-services ? {},
	...
}:

wrapperModules.nushell.apply (let
	inherit (pkgs) lib;
	
	servicesToCompletions = services: suffix: lib.pipe services [
			(lib.filterAttrs (name: value: value.enable))
			(lib.concatMapAttrsStringSep "\n" (name: value:
				''{ value: "${name}${suffix}", description: "${value.description}" }''
			))
		];
	
	scriptPlaceholders = {
		services = "${servicesToCompletions systemd-services ""}\n${servicesToCompletions systemd-user-services "%"}";
	};
	
	replacePlaceholders = let
		from = map (name: "@${name}@") (builtins.attrNames scriptPlaceholders);
		to = builtins.attrValues scriptPlaceholders;
	in builtins.replaceStrings from to;
	
	staticScripts = lib.pipe ./nushell [
		lib.filesystem.listFilesRecursive
		(map (file: rec {
			name = lib.pipe file [
				toString
				(builtins.split "/")
				lib.last
			];
			value = lib.pipe file [
				builtins.readFile
				replacePlaceholders
				(pkgs.writeText name)
			];
		}))
		builtins.listToAttrs
		(scripts: removeAttrs scripts ["nushell.nu"])
	];
	
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
		
		${lib.concatMapAttrsStringSep "\n" (name: value: "cp ${value} $out/${name}") staticScripts}
	'';
	
	nushellPlugins = pkgs.runCommand "nushell-plugins" {} ''
		${lib.getExe pkgs.nushell} --plugin-config $out -c "
			plugin add ${lib.getExe pkgs.nushellPlugins.desktop_notifications}
			plugin add ${lib.getExe pkgs.nushellPlugins.port_extension}
		"
	'';
in {
	inherit pkgs;
	
	"config.nu".content = builtins.readFile ./nushell/nushell.nu;
	
	flags = {
		"--plugin-config" = "${nushellPlugins}";
		"--include-path" = "${includeScripts}";
	};
	
	extraPackages = with pkgs; [
		zoxide
		fzf
	];
})
