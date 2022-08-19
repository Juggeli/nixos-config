{ config, lib, pkgs, modulesPath, ... }:

{ 
  imports =
    [ (modulesPath + "/profiles/qemu-guest.nix")
    ];

  boot = {
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "virtio_pci" "nvme" "usbhid" "sr_mod" "virtio_blk" ];
#    initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
#    #extraModulePackages = [ pkgs.linuxKernel.packages.linux_5_19.nvidia_x11 ];
#    blacklistedKernelModules = [ "noveau" ];
    kernelModules = [ "kvm-amd" ];
    kernelParams = [
      # HACK Disables fixes for spectre, meltdown, L1TF and a number of CPU
      #      vulnerabilities. Don't copy this blindly! And especially not for
      #      mission critical or server/headless builds exposed to the world.
      "mitigations=off"
#      "nvidia-drm.modeset=1"
    ];

    # Refuse ICMP echo requests on my desktop/laptop; nobody has any business
    # pinging them, unlike my servers.
    kernel.sysctl."net.ipv4.icmp_echo_ignore_broadcasts" = 1;
  };

  # Modules
  modules.hardware = {
    audio.enable = true;
    fs = {
      enable = true;
      ssd.enable = true;
    };
  };

  # CPU
  nix.settings.max-jobs = lib.mkDefault 10;

  boot.initrd.postDeviceCommands = pkgs.lib.mkBefore ''
    mkdir -m 0755 -p /key
    mount -n -t xfs -o ro `findfs LABEL=KEY` /key
  '';

  boot.initrd.luks.devices."root" = {
    device = "/dev/disk/by-uuid/e5f04527-d5a0-4656-9627-c58f0b115bdf";
    keyFile = "/key/keyFile";
    preLVM = false;
  };

  # Storage
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
  swapDevices = [];

  hardware.enableAllFirmware = true;

#  services.xserver.videoDrivers = [ "nvidia" ];
  # hardware.opengl.enable = true;
#  hardware.nvidia.nvidiaSettings = true;
  boot.loader.systemd-boot.consoleMode = "max";
}
