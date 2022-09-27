{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "usbhid" "usb_storage" "sd_mod" "sdhci_pci" "rtsx_usb_sdmmc" "igb" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/2efa0c7b-fe81-41c9-a496-495296ecd4ee";
      fsType = "xfs";
    };

  # boot.initrd.luks.devices."luks-537add52-44df-479d-a75e-3014e84dab79".device = "/dev/disk/by-uuid/537add52-44df-479d-a75e-3014e84dab79";

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/D3B6-4D8F";
      fsType = "vfat";
    };

  fileSystems."/mnt/cache" =
    { device = "/dev/disk/by-uuid/0527a5d8-9379-4edf-a6fc-409ed0da5562";
      fsType = "btrfs";
    };

  # boot.initrd.luks.devices."luks-5a26866b-fdc7-4bd7-9340-18d70b5d577b".device = "/dev/disk/by-uuid/5a26866b-fdc7-4bd7-9340-18d70b5d577b";

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp2s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp3s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlo2.useDHCP = lib.mkDefault true;

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  # high-resolution display
  hardware.video.hidpi.enable = lib.mkDefault true;
}
