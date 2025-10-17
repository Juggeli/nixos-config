{
  lib,
  config,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.services.tailscale;
in
{
  options.plusultra.services.tailscale = with types; {
    enable = mkBoolOpt false "Whether or not to configure Tailscale";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [ "tailscale" ];
  };
}
