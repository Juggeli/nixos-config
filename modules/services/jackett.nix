{ options, config, pkgs, lib, ... }:
with lib;
with lib.my;
let cfg = config.modules.services.jackett;
in
{
  options.modules.services.jackett = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.jackett = {
      enable = true;
      openFirewall = true;
      dataDir = "/mnt/pool/appdata/jackett";
    };
  };
}

