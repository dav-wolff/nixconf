{ lib, config, modulesPath, ... }:

{
	imports = ["${modulesPath}/installer/scan/not-detected.nix"];
	
	boot.initrd.availableKernelModules = [ "uhci_hcd" "ehci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "sr_mod" "sdhci_pci" ];
	boot.initrd.kernelModules = [ ];
	boot.kernelModules = [ ];
	boot.extraModulePackages = [ ];
	
	fileSystems."/" = {
		device = "/dev/disk/by-uuid/396b6015-2840-4d13-9017-cb8a1776eb19";
		fsType = "ext4";
	};
	
	fileSystems."/vol/nextcloud" = {
		device = "/dev/disk/by-uuid/0af2ff96-3bc7-43c3-896c-b8031460e563";
		fsType = "btrfs";
		options = [
			"subvol=nextcloud"
			"compress=zstd"
		];
	};
	
	modules.nextcloud.volume = "/vol/nextcloud";
	
	swapDevices = [{
		device = "/dev/disk/by-uuid/9729f4ae-45a1-4641-ae3e-cc94cbf069c7";
	}];
	
	# Enables DHCP on each ethernet and wireless interface. In case of scripted networking
	# (the default) this is the recommended approach. When using systemd-networkd it's
	# still possible to use this option, but it's recommended to use it in conjunction
	# with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
	networking.useDHCP = lib.mkDefault true;
	# networking.interfaces.enp2s0f5.useDHCP = lib.mkDefault true;
	# networking.interfaces.wlp3s0.useDHCP = lib.mkDefault true;
	
	nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
	hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
