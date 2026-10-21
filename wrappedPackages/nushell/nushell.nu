$env.config.history.file_format = "sqlite"
$env.config.history.isolation = true

$env.config.show_banner = false

$env.config.footer_mode = "auto"
$env.config.edit_mode = "helix"

$env.config.table.mode = "frameless"
$env.config.table.index_mode = "never"
$env.config.table.padding.left = 0
$env.config.table.padding.right = 0

$env.config.filesize.unit = "binary"

$env.config.hooks.display_output = "table -o"

alias nd = nix develop -c nu
alias ns = nix shell

source log.nu
source show-cmd.nu
source svc.nu

$env.PROMPT_COMMAND = {||
	mut prompt = ""
	
	let dir = match (do -i { $env.PWD | path relative-to $nu.home-dir}) {
		null => $env.PWD
		'' => '~'
		$relative_dir => ([~ $relative_dir] | path join)
	}
	let path_color = (if (is-admin) { ansi red_bold } else { ansi green_bold })
	let separator_color = (if (is-admin) { ansi light_red_bold } else { ansi light_green_bold })
	$prompt += $"($path_color)($dir)" | str replace --all (char path_sep) $"($separator_color)(char path_sep)($path_color)"
	
	if "SSH_CLIENT" in $env {
		$prompt += $" (ansi blue_bold)[(sys host | get hostname)]"
	}
	$"($prompt)\n"
}
$env.PROMPT_INDICATOR = "❯ "
$env.PROMPT_INDICATOR_VI_INSERT = "❯ "
$env.PROMPT_INDICATOR_VI_NORMAL = "⫼ "
$env.TRANSIENT_PROMPT_COMMAND = ""

source zoxide.nu

source fzf.nu
$env.config.keybindings = $env.config.keybindings | update keycode {|keybind|
	match $keybind.name {
		'fzf_history' => 'char_w'
		_ => $keybind.keycode
	}
}

use completions-jj.nu *

# required by gpg
$env.GPG_TTY = (tty)
