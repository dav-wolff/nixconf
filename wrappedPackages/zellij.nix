{ pkgs, wrapperModules, ... }:

wrapperModules.zellij.apply {
	inherit pkgs;
	settings = builtins.readFile ./zellij.kdl;
}
