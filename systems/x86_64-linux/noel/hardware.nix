{
  modulesPath,
  inputs,
  ...
}:

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

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = true;
    nvidiaSettings = true;
  };

  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "nvme"
      "usbhid"
      "aesni_intel"
    ];

    kernelModules = [ "kvm-intel" ];
    kernelParams = [
      "mitigations=off"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    ];

    loader.grub.mirroredBoots = [
      {
        devices = [ "nodev" ];
        path = "/boot";
      }
      {
        devices = [ "nodev" ];
        path = "/boot-fallback";
      }
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/7B72-0BC4";
    fsType = "vfat";
  };

  fileSystems."/boot-fallback" = {
    device = "/dev/disk/by-uuid/E74E-4B34";
    fsType = "vfat";
  };

  networking = {
    interfaces.enp5s0.useDHCP = true;
    hostId = "cc5b25a0";
  };

  hardware.enableRedistributableFirmware = true;

  hardware.cpu.intel.updateMicrocode = true;
}
