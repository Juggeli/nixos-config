{ options, config, lib, pkgs, ... }:

with lib;
with lib.internal;
let
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

      cli-apps = {
        flake = enabled;
        neovim = enabled;
        vifm = enabled;
      };

      tools = {
        git = enabled;
        misc = enabled;
      };

      hardware = {
        audio = enabled;
        storage = enabled;
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
        boot = enabled;
        fonts = enabled;
        locale = enabled;
        time = enabled;
      };
    };
  };
}
