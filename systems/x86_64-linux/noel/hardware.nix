{ config, lib, pkgs, modulesPath, inputs, ... }:

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
    kernelPackages = pkgs.linuxPackages_latest;

    initrd = {
      availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "aesni_intel" ];
      luks.devices."root" = {
        device = "/dev/disk/by-uuid/e5f04527-d5a0-4656-9627-c58f0b115bdf";
        preLVM = false;
      };
    };
    
    kernelModules = [ "kvm-intel" ];
    kernelParams = [
      "mitigations=off"
    ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/2bcb9f9c-f7cc-4b7e-86fd-7ff56dece8a8";
      fsType = "xfs";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/B489-4312";
      fsType = "vfat";
    };
  };
  swapDevices = [ ];

  networking.interfaces.enp5s0.useDHCP = false;

  hardware.enableRedistributableFirmware = true;

  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
}