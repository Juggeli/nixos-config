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
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/ed75df82-8e87-4d1d-9256-d360b3eaaf3a";
      fsType = "xfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/2A12-EEC8";
      fsType = "vfat";
    };

  # fileSystems."/mnt/cache" =
  #   { device = "/dev/disk/by-uuid/0527a5d8-9379-4edf-a6fc-409ed0da5562";
  #     fsType = "btrfs";
  #   };

  boot.initrd.luks.devices = {
    root = {
      preLVM = true;
      device = "/dev/disk/by-uuid/e62e2d61-7a84-48a6-b130-3b0b8f8bc365";
      allowDiscards = true;
    };
    # data = {
    #   preLVM = true;
    #   device = "/dev/disk/by-uuid/5a26866b-fdc7-4bd7-9340-18d70b5d577b";
    #   allowDiscards = true;
    # };
  };

  swapDevices = [ ];

  hardware.cpu.intel.updateMicrocode = true;
}

