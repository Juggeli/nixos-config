{ config, lib, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.filesystem.tmpfs;
in
{
  options.plusultra.filesystem.tmpfs = with types; {
    enable = mkOption {
      default = false;
      type = with types; bool;
      description = "Enables tmpfs on /tmp mount during boot";
    };
    size = mkOption {
      default = "50%";
      type = with types; oneOf [ types.str types.types.ints.positive ];
      description = "Size of TMPFS";
    };
  };

  config = mkIf cfg.enable {
    boot = {
      tmp = {
        useTmpfs = true;
        tmpfsSize = cfg.size;
      };
    };
  };
}
