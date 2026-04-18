{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.av1an;
in
{
  options.plusultra.containers.av1an = with types; {
    enable = mkBoolOpt false "Whether or not to enable av1an encoding container.";
    inputPath = mkOption {
      type = str;
      default = "/tank/media/anime";
      description = "Path to source anime files.";
    };
    outputPath = mkOption {
      type = str;
      default = "/tank/media/anime-av1";
      description = "Path for encoded output files.";
    };
    sonarr = {
      url = mkOption {
        type = str;
        default = "http://10.11.11.2:8999";
        description = "Sonarr Anime API URL.";
      };
      apiKeyFile = mkOption {
        type = nullOr path;
        default = null;
        description = "Path to file containing Sonarr API key.";
      };
    };
  };

  config = mkIf cfg.enable {
    environment.shellAliases = {
      encode-anime =
        let
          sonarrKeyArg =
            if cfg.sonarr.apiKeyFile != null then
              ''-e SONARR_API_KEY="$(cat ${cfg.sonarr.apiKeyFile})"''
            else
              "";
        in
        concatStringsSep " " [
          "sudo podman run -it --rm"
          "--network=host"
          "-v ${cfg.inputPath}:/input:ro"
          "-v ${cfg.outputPath}:/output"
          "-v /mnt/appdata/av1an:/app/tools-config"
          "-e SONARR_URL=${cfg.sonarr.url}"
          sonarrKeyArg
          "localhost/av1an"
        ];
    };
  };
}
