{ options, config, pkgs, lib, ... }:

with lib;
with lib.internal;
let cfg = config.plusultra.services.syncthing;
in
{
  options.plusultra.services.syncthing = with types; {
    enable = mkBoolOpt false "Whether or not to enable syncthing service.";
  };

  config = mkIf cfg.enable {
    services = {
      syncthing = {
        enable = true;
        user = "juggeli";
        dataDir = "/home/juggeli/documents"; # Default folder for new synced folders
        configDir = "/home/juggeli/documents/.config/syncthing"; # Folder for Syncthing's settings and keys
      };
    };
  };
}

