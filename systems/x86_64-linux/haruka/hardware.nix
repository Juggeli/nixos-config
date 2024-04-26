{ config, lib, modulesPath, inputs, ... }:

let
  inherit (inputs) nixos-hardware;
in
{
  imports = with nixos-hardware.nixosModules; [
    (modulesPath + "/installer/scan/not-detected.nix")
    common-cpu-intel
    common-pc
    common-pc-ssd
  ];

  boot = {
    initrd = {
      availableKernelModules = [
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
      luks.devices = {
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
    };

    kernelModules = [ "kvm-intel" ];
    kernelParams = [
      "mitigations=off"
    ];
  };

  # Generate with: head -c4 /dev/urandom | od -A none -t x4
  networking.hostId = "37bf5335";

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/c5de15d7-1543-485e-b480-a429ebdb9c57";
      fsType = "xfs";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/2A12-EEC8";
      fsType = "vfat";
    };
    "/mnt/appdata" = {
      device = "/dev/disk/by-uuid/78cab7c2-db29-4b6f-9668-6c6519d51b9c";
      fsType = "btrfs";
    };
  };

  swapDevices = [{
    device = "/mnt/appdata/swapfile";
    size = 16 * 1024;
    priority = 1;
  }];

  zramSwap = {
    enable = true;
  };

  hardware.enableRedistributableFirmware = true;

  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
}
