def l [
	--all (-a) # Show hidden files.
	...pattern: glob # The glob pattern to use.
]: nothing -> string {
	let max_width = ((term size | get columns) - 1) / 2 - 4 | math floor
	let pattern = if ($pattern | is-empty) { [ '.' ] } else { $pattern }
	(ls -s --all=$all ...$pattern)
		| sort-by type name -i
		| get name
		| each {|name|
			if ($name | str length) > $max_width {
				let shortened = str substring 0..=($max_width - 2)
				$"($shortened)…"
			} else {
				$name
			}
		}
		| grid -c -i
}
