{ config, lib, modulesPath, ... }:

{
	imports = [(modulesPath + "/installer/scan/not-detected.nix")];
	
	boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" ];
	boot.initrd.kernelModules = [ ];
	boot.kernelModules = [ "kvm-intel" ];
	boot.extraModulePackages = [ ];
	
	fileSystems."/" = {
		device = "/dev/disk/by-label/NixOS";
		fsType = "ext4";
	};
	
	fileSystems."/boot/efi" = {
		device = "/dev/disk/by-label/NIXOS\\x20EFI";
		fsType = "vfat";
		options = ["fmask=0077" "dmask=0077" "defaults"];
	};
	
	fileSystems."/vol/backup" = {
		device = "/dev/disk/by-label/HDD";
		fsType = "btrfs";
		options = [
			"subvol=backup"
			"compress=zstd"
		];
	};
	
	swapDevices = [ ];
	
	# Enables DHCP on each ethernet and wireless interface. In case of scripted networking
	# (the default) this is the recommended approach. When using systemd-networkd it's
	# still possible to use this option, but it's recommended to use it in conjunction
	# with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
	networking.useDHCP = lib.mkDefault true;
	# networking.interfaces.enp7s0.useDHCP = lib.mkDefault true;
	
	nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
	powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
	hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
