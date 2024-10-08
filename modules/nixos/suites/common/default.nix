{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.suites.common;
in
{
  options.plusultra.suites.common = with types; {
    enable = mkBoolOpt false "Whether or not to enable common configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.plusultra.list-iommu
    ];

    plusultra = {
      nix = enabled;

      tools = {
        misc = enabled;
      };

      hardware = {
        audio = enabled;
        storage = enabled;
        networking = enabled;
      };

      services = {
        printing = enabled;
        openssh = enabled;
        tailscale = enabled;
      };

      security = {
        doas = enabled;
      };

      system = {
        fonts = enabled;
        locale = enabled;
        time = enabled;
      };

      feature = {
        boot = enabled;
        podman = enabled;
      };
    };
  };
}
