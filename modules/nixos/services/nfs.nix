{ config, lib, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.services.nfs;
in
{
  options.plusultra.services.nfs = with types; {
    enable = mkBoolOpt false "Whether or not to enable nfs.";
  };

  config = mkIf cfg.enable {
    services.nfs.server.enable = true;
    networking.firewall.allowedTCPPorts = [ 2049 ];
  };
}
