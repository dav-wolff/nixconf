{ pkgs }:

let
	zsh = pkgs.zsh;
	
	compiledConfig = pkgs.runCommand "${zsh.name}-config" {
		pname = "${zsh.name}-config";
		nativeBuildInputs = [zsh];
	} (with pkgs; ''
		mkdir $out
		cp ${./zsh/zshrc.zsh} $out/.zshrc
		cp ${./zsh/p10k.zsh} $out/p10k.zsh
		sed -i "s\@P10K@\${zsh-powerlevel10k}/share/zsh-powerlevel10k\g" $out/.zshrc
		sed -i "s\@DEFER@\${zsh-defer}/share/zsh-defer\g" $out/.zshrc
		sed -i "s\@SYNTAX_HIGHLIGHTING@\${zsh-syntax-highlighting}/share/zsh-syntax-highlighting\g" $out/.zshrc
		sed -i "s\@COMPLETIONS@\${zsh-completions}/share/zsh/site-functions\g" $out/.zshrc
		sed -i "s\@AUTOSUGGESTIONS@\${zsh-autosuggestions}/share/zsh-autosuggestions\g" $out/.zshrc
		zsh -c "zcompile $out/.zshrc"
		zsh -c "zcompile $out/p10k.zsh"
	'');
in
	pkgs.runCommand zsh.name {
		inherit (zsh) pname version meta;
		outputs = ["out" "man"];
		nativeBuildInputs = [pkgs.makeWrapper];
	} ''
		cp -rs --no-preserve=mode,ownership ${zsh.man} $man
		cp -rs --no-preserve=mode,ownership ${zsh} $out
		wrapProgram "$out/bin/zsh" --set ZDOTDIR ${compiledConfig}
	''
