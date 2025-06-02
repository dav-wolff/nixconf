{ lib
, writeTextFile
, bash
, unindent
, ripgrep
, wrapPackage
}:

package: {
	env ? {},
	args ? [],
	passthru ? {},
	extraOutputs ? [],
	replaceDerivationInFiles ? false
} @ wrapArgs: let
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
		passthru = passthru // {
			override = overrideArgs: wrapPackage (package.override overrideArgs) wrapArgs;
		};
		outputs = ["out"] ++ extraOutputs;
		nativeBuildInputs = lib.optional replaceDerivationInFiles ripgrep;
	};
	
	checkPhase = let
		linkExtraOutputs = lib.concatMapStrings (output:
			"ln -s ${lib.getOutput output package} ${"$" + output}"
		) extraOutputs;
	in unindent ''
		${linkExtraOutputs}
		${if replaceDerivationInFiles then ''
			for f in ${package}/* ; do
				[[ "$f" = "${package}/bin" ]] && continue
				name=$(basename $f)
				cp -r $f $out/$name
			done
			for f in $(rg --files-with-matches "${package}" $out) ; do
				[[ "$f" = $out/bin/* ]] && continue
				echo $f
				substituteInPlace $f --replace-quiet "${package}" "$out"
			done
		'' else ''
			for f in ${package}/* ; do
				[[ "$f" = "${package}/bin" ]] && continue
				name=$(basename $f)
				ln -s $f $out/$name
			done
		''}
	'';
	
	text = unindent ''
		#! ${lib.getExe bash} -e
		${lib.strings.concatMapStrings (name: ''
		 export ${name}='${escapeString env.${name}}'
		'') (builtins.attrNames env)}
		exec -a "$0" "${lib.getExe package}" ${argsString} "$@"
	'';
}
