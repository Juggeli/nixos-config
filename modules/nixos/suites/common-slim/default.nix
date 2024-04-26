{ config, lib, pkgs, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.suites.common-slim;
in
{
  options.plusultra.suites.common-slim = with types; {
    enable = mkBoolOpt false "Whether or not to enable common configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.plusultra.list-iommu
    ];

    plusultra = {
      nix = enabled;
      feature.earlyoom = enabled;

      tools = {
        misc = enabled;
      };

      hardware = {
        storage = enabled;
      };

      services = {
        openssh = enabled;
        tailscale = enabled;
      };

      security = {
        doas = enabled;
      };

      system = {
        boot = enabled;
        fonts = enabled;
        locale = enabled;
        time = enabled;
      };
    };
  };
}
