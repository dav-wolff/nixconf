{lib}:

text: let
	inherit (builtins) length head match stringLength substring concatStringsSep;
	inherit (lib) min splitString findFirst imap0 drop;
	
	countIndentation = line: stringLength (head (match "^(\t*).*" line));
	lines = splitString "\n" text;
	firstNonEmptyLine = (findFirst
			(el: el.line != "")
			{index = length lines;}
			(imap0 (index: line: {inherit index line;}) lines)
		).index;
	trimmedLines = drop firstNonEmptyLine lines;
	baseIndentation = countIndentation (head trimmedLines);
	unindent = line: substring (min baseIndentation (countIndentation line)) (stringLength line) line;
in concatStringsSep "\n" (map unindent lines)
