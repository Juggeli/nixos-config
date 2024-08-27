{ config, lib, ... }:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.services.cockpit;
in
{
  options.plusultra.services.cockpit = with types; {
    enable = mkBoolOpt false "Whether or not to enable cockpit.";
  };

  config = mkIf cfg.enable {
    services.cockpit = {
      enable = true;
      openFirewall = true;
    };
  };
}
