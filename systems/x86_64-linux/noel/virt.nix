{ lib, pkgs, ... }:

let
  gpuIDs = [
    "10de:1e81"
    "10de:10f8"
    "10de:1ad8"
    "10de:1ad9"
  ];
in
{
  config = {
    boot = {
      initrd.kernelModules = [
        "vfio_pci"
        "vfio"
        "vfio_iommu_type1"
      ];

      kernelParams = [
        # enable IOMMU
        "intel_iommu=on"
        ("vfio-pci.ids=" + lib.concatStringsSep "," gpuIDs)
      ];
    };
    virtualisation.spiceUSBRedirection.enable = true;

    plusultra.user.extraGroups = [ "libvirtd" ];

    virtualisation.libvirtd = {
      enable = true;
      onBoot = "ignore";
      onShutdown = "shutdown";
      qemu = {
        ovmf.enable = true;
        runAsRoot = true;
      };
    };

    programs.dconf.enable = true;
    environment.systemPackages = with pkgs; [ virt-manager ];
  };
}

