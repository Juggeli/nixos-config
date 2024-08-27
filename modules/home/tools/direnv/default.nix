{ config, lib, ... }:

with lib;
with lib.plusultra;
let
  cfg = config.plusultra.tools.direnv;
in
{
  options.plusultra.tools.direnv = with types; {
    enable = mkBoolOpt false "Whether or not to enable direnv.";
  };

  config = mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv = enabled;
    };
  };
}
