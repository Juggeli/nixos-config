{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.services.plex;
in {
  options.modules.services.plex = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.plex = {
      enable = true;
      openFirewall = true;
      dataDir = "/mnt/pool/appdata/plex";
      extraScanners = [
        (pkgs.fetchFromGitHub {
          owner = "ZeroQI";
          repo = "Absolute-Series-Scanner";
          rev = "9c8ce030d3251951880cd03b925018a475eae2ae";
          sha256 = "069w327bg5isfyszajrq6vadn9bkwff2k2s7wxa15mk01kl06085";
        })
      ];
      extraPlugins = [
        (builtins.path {
          name = "Hama.bundle";
          path = pkgs.fetchFromGitHub {
            owner = "ZeroQI";
            repo = "Hama.bundle";
            rev = "b2a0ac4b57c83d6b6f6c174e08e1cc6d605d2a2a";
            sha256 = "1zcbnbdc9j9yz572x8127ap3q9nfl0vlvja45adwr0zrc2shjjy7";
          };
        })
      ];
    };
  };
}
