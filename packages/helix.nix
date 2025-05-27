{ wrapPackage
, runCommandLocal
, helix
, formats
}:

let
	config = {
		theme = "blue";
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
			end-of-line-diagnostics = "hint";
			inline-diagnostics = {
				cursor-line = "warning";
				other-lines = "disable";
			};
		};
		keys = {
			normal.space = {
				i = ":toggle-option lsp.display-inlay-hints";
				e = ":toggle-option inline-diagnostics.other-lines disable error";
			};
		};
	};
	
	toml = formats.toml {};
	configFile = toml.generate "helix-config" config;
	
	runtimeDirectory = runCommandLocal "helix-themes" {} ''
		mkdir -p $out/themes
		cp ${./helix-theme.toml} $out/themes/blue.toml
	'';
in wrapPackage helix {
	args = ["--config" configFile];
	env = {
		HELIX_RUNTIME = runtimeDirectory;
	};
}
