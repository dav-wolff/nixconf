{ pkgs, helix }:

let
	config = {
		editor = {
			mouse = false;
			line-number = "relative";
			cursor-shape.insert = "bar";
			scrolloff = 8;
			cursorline = true;
			idle-timeout = 0;
			bufferline = "multiple";
			color-modes = true;
			true-color = true;
			auto-format = false;
			whitespace = {
				render.space = "all";
				render.tab = "all";
				render.newline = "none";
				characters = {
					space = "·";
					nbsp = "⍽";
					tab = "├"; /* ├╌╌╌ */
					tabpad = "╌";
				};
			};
		};
		keys = {
			normal.space = {
				i = ":toggle-option lsp.display-inlay-hints";
			};
		};
	};
	
	toml = pkgs.formats.toml {};
	
	configFile = toml.generate "helix-config" config;
in
helix.override {
	makeWrapperArgs = ["--add-flags" "\"--config\"" "--add-flags" "\"${configFile}\""];
}
