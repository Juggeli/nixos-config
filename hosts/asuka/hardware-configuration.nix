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
    "igb"
    "aesni_intel"
    "cryptd"
    "nvme"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/2efa0c7b-fe81-41c9-a496-495296ecd4ee";
      fsType = "xfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/D3B6-4D8F";
      fsType = "vfat";
    };

  fileSystems."/mnt/cache" =
    { device = "/dev/disk/by-uuid/0527a5d8-9379-4edf-a6fc-409ed0da5562";
      fsType = "btrfs";
    };

  boot.initrd.luks.devices = {
    root = {
      preLVM = true;
      device = "/dev/disk/by-uuid/537add52-44df-479d-a75e-3014e84dab79";
      allowDiscards = true;
    };
    data = {
      preLVM = true;
      device = "/dev/disk/by-uuid/5a26866b-fdc7-4bd7-9340-18d70b5d577b";
      allowDiscards = true;
    };
  };

  swapDevices = [ ];

  hardware.cpu.intel.updateMicrocode = true;
}
