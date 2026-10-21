def show-cmd [
	command: string
]: nothing -> string {
	which $command
	| first
	| get path
	| bat $in
}
