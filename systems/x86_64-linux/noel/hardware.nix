{
  pkgs,
  modulesPath,
  inputs,
  config,
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
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  boot = {

    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "nvme"
      "usbhid"
      "aesni_intel"
    ];
    kernelPackages = pkgs.linuxPackages_latest;

    kernelModules = [ "kvm-intel" ];
    kernelParams = [
      "mitigations=off"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    ];
  };

  networking.interfaces.enp5s0.useDHCP = false;

  hardware.enableRedistributableFirmware = true;

  hardware.cpu.intel.updateMicrocode = true;
}
