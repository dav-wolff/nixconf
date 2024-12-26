{ lib
, runCommand
, makeWrapper
, alacritty
, formats
, shell
}:

let
	config = {
		general.live_config_reload = false;
		terminal.shell = lib.meta.getExe shell;
		window.startup_mode = "Maximized";
		mouse.hide_when_typing = true;
		font = let
			font = {
				family = "JetBrainsMono Nerd Font";
			};
		in {
			size = 13;
			builtin_box_drawing = false;
			normal = font;
			bold = font;
			italic = font;
			bold_italic = font;
		};
		env.NERD_FONT = "1";
	};
	
	toml = formats.toml {};
	
	configFile = toml.generate "alacritty-config" config;
in
	runCommand alacritty.name {
		inherit (alacritty) pname version meta;
		nativeBuildInputs = [makeWrapper];
	} ''
		cp -rs --no-preserve=mode,ownership ${alacritty} $out
		wrapProgram "$out/bin/alacritty" --add-flags --config-file --add-flags "${configFile}"
	''
