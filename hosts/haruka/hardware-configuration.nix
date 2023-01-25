{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ 
    "ahci"
    "xhci_pci"
    "usbhid"
    "usb_storage"
    "sd_mod"
    "sdhci_pci"
    "rtsx_usb_sdmmc"
    "r8169"
    "aesni_intel"
    "cryptd"
    "nvme"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/c5de15d7-1543-485e-b480-a429ebdb9c57";
      fsType = "xfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/2A12-EEC8";
      fsType = "vfat";
    };

  fileSystems."/mnt/appdata" =
    { device = "/dev/disk/by-uuid/78cab7c2-db29-4b6f-9668-6c6519d51b9c";
      fsType = "btrfs";
    };

  boot.initrd.luks.devices = {
    root = {
      preLVM = true;
      device = "/dev/disk/by-uuid/e62e2d61-7a84-48a6-b130-3b0b8f8bc365";
      allowDiscards = true;
    };
    appdata = {
      preLVM = true;
      device = "/dev/disk/by-uuid/5f527a43-bef3-4a80-9465-9dfb13be9831";
      allowDiscards = true;
    };
  };

  swapDevices = [ ];

  hardware.cpu.intel.updateMicrocode = true;
}

