{ lib
, runCommand
, makeWrapper
, zsh
, zsh-powerlevel10k
, zsh-defer
, zsh-syntax-highlighting
, zsh-completions
, zsh-autosuggestions
, fzf
, zoxide
}:

let
	templateReplacements = {
		P10K = "${zsh-powerlevel10k}/share/zsh-powerlevel10k";
		DEFER = "${zsh-defer}/share/zsh-defer";
		SYNTAX_HIGHLIGHTING = "${zsh-syntax-highlighting}/share/zsh-syntax-highlighting";
		COMPLETIONS = "${zsh-completions}/share/zsh/site-functions";
		AUTOSUGGESTIONS = "${zsh-autosuggestions}/share/zsh-autosuggestions";
		FZF = "${fzf}/bin";
		ZOXIDE = "${zoxide}/bin";
	};
	
	templateReplace = lib.concatMapStrings (name:
		let
			value = builtins.getAttr name templateReplacements;
		in ''s\@${name}@\${value}\g;''
	) (builtins.attrNames templateReplacements);
	
	compiledConfig = runCommand "${zsh.name}-config" {
		pname = "${zsh.name}-config";
		nativeBuildInputs = [zsh];
	} ''
		mkdir $out
		cp ${./zsh/zshrc.zsh} $out/.zshrc
		cp ${./zsh/p10k_nerd_font.zsh} $out/p10k_nerd_font.zsh
		cp ${./zsh/p10k_tty.zsh} $out/p10k_tty.zsh
		sed -i "${templateReplace}" $out/.zshrc
		zsh -c "zcompile $out/.zshrc"
		zsh -c "zcompile $out/p10k_nerd_font.zsh"
		zsh -c "zcompile $out/p10k_tty.zsh"
	'';
in
	runCommand zsh.name {
		inherit (zsh) pname version meta;
		outputs = ["out" "man"];
		nativeBuildInputs = [makeWrapper];
		passthru.shellPath = "/bin/zsh";
	} ''
		cp -rs --no-preserve=mode,ownership ${zsh.man} $man
		cp -rs --no-preserve=mode,ownership ${zsh} $out
		wrapProgram "$out/bin/zsh" --set ZDOTDIR ${compiledConfig}
	''
