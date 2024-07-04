{ pkgs, modulesPath, inputs, config, ... }:

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

  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_6_8;

    initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "aesni_intel" ];

    kernelModules = [ "kvm-intel" ];
    kernelParams = [
      "mitigations=off"
      "NVreg_PreserveVideoMemoryAllocations=1"
    ];
  };

  networking.interfaces.enp5s0.useDHCP = false;

  hardware.enableRedistributableFirmware = true;

  hardware.cpu.intel.updateMicrocode = true;
}
