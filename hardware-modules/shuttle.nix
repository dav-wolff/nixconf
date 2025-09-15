{ lib, config, modulesPath, ... }:

{
	imports = ["${modulesPath}/installer/scan/not-detected.nix"];
	
	boot.initrd.availableKernelModules = [ "uhci_hcd" "ehci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "sr_mod" "sdhci_pci" ];
	boot.initrd.kernelModules = [ ];
	boot.kernelModules = [ ];
	boot.extraModulePackages = [ ];
	
	fileSystems."/" = {
		device = "/dev/disk/by-label/nixos";
		fsType = "ext4";
	};
	
	fileSystems."/vol/immich" = {
		device = "/dev/disk/by-label/T7";
		fsType = "btrfs";
		options = [
			"subvol=immich"
			"compress=zstd"
		];
	};
	
	modules.immich.volume = "/vol/immich";
	
	fileSystems."/vol/navidrome" = {
		device = "/dev/disk/by-label/T7";
		fsType = "btrfs";
		options = [
			"subvol=navidrome"
			"compress=zstd"
		];
	};
	
	modules.navidrome.volume = "/vol/navidrome";
	
	fileSystems."/vol/filebrowser" = {
		device = "/dev/disk/by-label/T7";
		fsType = "btrfs";
		options = [
			"subvol=filebrowser"
			"compress=zstd"
		];
	};
	
	modules.filebrowser.volume = "/vol/filebrowser";
	
	swapDevices = [{
		device = "/dev/disk/by-label/swap";
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
