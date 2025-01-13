{ lib
, writeTextFile
, bash
, unindent
}:

package: {
	env ? {},
	args ? [],
	passthru ? {},
	extraOutputs ? []
}: let
	start = builtins.stringLength (lib.getBin package);
	len = builtins.stringLength (lib.getExe package) - start;
	path = builtins.substring start len (lib.getExe package);
	
	escapeString = string: lib.replaceStrings ["'"] ["'\\''"] (toString string);
	argsString = lib.strings.concatMapStringsSep " " escapeString args;
in writeTextFile {
	inherit (package) name meta;
	destination = path;
	executable = true;
	
	derivationArgs = {
		inherit passthru;
		outputs = ["out"] ++ extraOutputs;
	};
	
	checkPhase = let
		linkExtraOutputs = lib.concatMapStrings (output:
			"ln -s ${lib.getOutput output package} ${"$" + output}"
		) extraOutputs;
	in unindent ''
		${linkExtraOutputs}
		for f in ${package}/* ; do
			[ "$f" = "${package}/bin" ] && continue
			name=$(basename $f)
			ln -s $f $out/$name
		done
	'';
	
	text = unindent ''
		#! ${lib.getExe bash} -e
		${lib.strings.concatMapStrings (name: ''
		 export ${name}='${escapeString env.${name}}'
		'') (builtins.attrNames env)}
		exec -a "$0" "${lib.getExe package}" ${argsString} "$@"
	'';
}
