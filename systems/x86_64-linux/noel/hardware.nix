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
    driSupport = true;
    driSupport32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_cachyos;

    initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "aesni_intel" ];

    kernelModules = [ "kvm-intel" ];
    kernelParams = [
      "mitigations=off"
    ];
  };

  networking.interfaces.enp5s0.useDHCP = false;

  hardware.enableRedistributableFirmware = true;

  hardware.cpu.intel.updateMicrocode = true;
}
