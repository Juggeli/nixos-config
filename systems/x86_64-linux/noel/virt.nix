{ config, lib, pkgs, modulesPath, inputs, ... }:

let
in
{
  config.virtualisation.spiceUSBRedirection.enable = true;

  config.plusultra.user.extraGroups = [ "libvirtd" ];

  config.virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";
    onShutdown = "shutdown";
    qemuOvmf = true;
    qemuRunAsRoot = true;
  };
}

