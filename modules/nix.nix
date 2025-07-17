{ config, lib, pkgs, ... }:

let
	cfg = config.modules.nix;
in {
	options.modules.nix = {
		pkgs = lib.mkOption {
			type = lib.types.pathInStore;
		};
	};
	
	config = {
		nix = {
			settings = {
				experimental-features = [
					"nix-command"
					"flakes"
				];
				
				substituters = [
					"https://cache.nixos.org"
					"https://nix-community.cachix.org"
				];
				
				trusted-public-keys = [
					"hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs="
					"nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
				];
				
				trusted-users = ["root" "dav"];
				
				# https://github.com/NixOS/nix/issues/9574
				nix-path = "nixpkgs=flake:nixpkgs";
			};
			
			registry = {
				# nixpkgs with local overlays
				pkgs = {
					from = {
						id = "pkgs";
						type = "indirect";
					};
					flake = cfg.pkgs;
				};
				# unpin nixpkgs flake, not sure why it's pinned without this
				nixpkgs = {
					from = {
						id = "nixpkgs";
						type = "indirect";
					};
					to = {
						owner = "NixOS";
						repo = "nixpkgs";
						type = "github";
					};
				};
			};
			
			# Not working?
			channel.enable = false;
			nixPath = ["nixpkgs=flake:nixpkgs"];
		};
		
		nixpkgs.flake.setNixPath = false;
		nixpkgs.config.allowUnfree = true;
		
		environment.systemPackages = with pkgs; [
			nixd
			nix-tree
			manix
			nix-output-monitor
		];
		
		programs.nh = {
			enable = true;
			flake = "/home/dav/nixconf";
		};
	};
}
