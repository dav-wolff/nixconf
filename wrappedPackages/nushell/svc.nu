module commands {
	def services []: nothing -> list {
		[@services@]
	}
	
	def unit-flags [
		unit: string
		--unit-flag (-u)
	]: nothing -> list {
		mut unit = $unit
		let flags = if ($unit | str ends-with "%") {
			$unit = $unit | str substring ..-2
			["--user"]
		} else {
			[]
		}
		
		$flags | append (if $unit_flag {
			["-u" $unit]
		} else {
			[$unit]
		})
	}
	
	export def svc []: nothing -> string {
		help svc
	}
	
	export def "svc log" [
		unit: string@services # The unit to show logs for. Append '%' for user units.
		--duration (-d): duration # Limit the log to everything that occured within a given duration
		--follow (-f) # Continuously print new log entries
		--highlight (-h) # Highlight as log
	]: nothing -> string {
		mut flags = []
		
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
		
		$flags = $flags | append "--output=cat" "--no-pager" (unit-flags -u $unit)
		
		if $highlight {
			journalctl ...($flags) | bat -pp --language log
		} else {
			journalctl ...($flags)
		}
	}
	
	export def "svc start" [
		unit: string@services # The unit to start
	]: nothing -> string {
		systemctl start ...(unit-flags $unit)
	}
	
	export def "svc stop" [
		unit: string@services # The unit to stop
	]: nothing -> string {
		systemctl stop ...(unit-flags $unit)
	}
	
	export def "svc restart" [
		unit: string@services # The unit to restart
	]: nothing -> string {
		systemctl restart ...(unit-flags $unit)
	}
	
	export def "svc st" [
		unit: string@services # The unit to get the status of
	]: nothing -> string {
		systemctl status --no-pager --lines 3 ...(unit-flags $unit)
	}
}

use commands *
