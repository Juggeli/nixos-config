{ config, lib, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.services.plex;
in
{
  options.plusultra.services.plex = with types; {
    enable = mkBoolOpt false "Whether or not to enable plex service.";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.plex = {
      image = "ghcr.io/hotio/plex";
      autoStart = true;
      ports = [ "32400:32400" ];
      extraOptions = [
        ''--device="/dev/dri/renderD128:/dev/dri/renderD128"''
      ];
      volumes = [
        "/mnt/appdata/plexnew/:/config"
        "/mnt/pool/media/:/mnt/pool/media"
        "/mnt/appdata/transcode/:/transcode"
      ];
    };

    # services.plex = {
    #   enable = true;
    #   openFirewall = true;
    #   dataDir = "/mnt/appdata/plex";
    #   extraScanners = [
    #     (pkgs.fetchFromGitHub {
    #       owner = "ZeroQI";
    #       repo = "Absolute-Series-Scanner";
    #       rev = "9c8ce030d3251951880cd03b925018a475eae2ae";
    #       sha256 = "069w327bg5isfyszajrq6vadn9bkwff2k2s7wxa15mk01kl06085";
    #     })
    #   ];
    #   extraPlugins = [
    #     (builtins.path {
    #       name = "Hama.bundle";
    #       path = pkgs.fetchFromGitHub {
    #         owner = "ZeroQI";
    #         repo = "Hama.bundle";
    #         rev = "b2a0ac4b57c83d6b6f6c174e08e1cc6d605d2a2a";
    #         sha256 = "1zcbnbdc9j9yz572x8127ap3q9nfl0vlvja45adwr0zrc2shjjy7";
    #       };
    #     })
    #   ];
    # };
  };
}
