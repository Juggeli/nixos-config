{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let
  cfg = config.modules.hardware.nvidia;
  nvidiaPackage = config.boot.kernelPackages.nvidiaPackages.beta;
in
{
  options.modules.hardware.nvidia = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware = {
      nvidia = {
        package = nvidiaPackage;
        nvidiaSettings = true;
        modesetting.enable = true;
        open = false;
        powerManagement.enable = false;
      };
      opengl = {
        enable = true;
        extraPackages = with pkgs; [
          nvidia-vaapi-driver
        ];
      };
    };

    # environment.variables = {
    #   GBM_BACKEND = "nvidia-drm";
    #   __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    #   WLR_RENDERER = "vulkan";
    #   WLR_NO_HARDWARE_CURSORS = "1";
    #   # WLR_DRM_NO_ATOMIC = "1";
    #   LIBVA_DRIVER_NAME = "nvidia";
    #   EGL_PLATFORM = "wayland";
    # };
  };
}
