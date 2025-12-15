{ pkgs, wrapperModules, shell, ... }:

wrapperModules.alacritty.apply {
	inherit pkgs;
	
	settings = {
		general.live_config_reload = false;
		terminal.shell = pkgs.lib.meta.getExe shell;
		window = {
			startup_mode = "Windowed";
			opacity = 0.8;
		};
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
}
