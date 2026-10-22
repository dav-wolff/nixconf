def svc [] {
	"Usage:\nsvc log"
}

def services []: nothing -> list {
	[@services@]
}

def "svc log" [
	unit: string@services # The unit to show logs for
	--user (-u) # Show user units instead of system units
	--duration (-d): duration # Limit the log to everything that occured within a given duration
	--follow (-f) # Continuously print new log entries
	--highlight (-h) # Highlight as log
]: nothing -> string {
	mut flags = []
	if $user {
		$flags = $flags | append "--user"
	}
	
	if ($duration | describe) != 'nothing' {
		let since = (date now) - $duration
			| format date "%Y-%m-%d %H:%M:%S"
		$flags = $flags | append "--since" $since
	} else {
		$flags = $flags | append "--invocation=0"
	}
	
	if $follow {
		$flags = $flags | append "--follow"
	}
	
	$flags = $flags | append "--output" "cat" "--no-pager" "-u" $unit
	
	if $highlight {
		journalctl ...($flags) | bat -pp --language log
	} else {
		journalctl ...($flags)
	}
}
