{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.containers.recyclarr;
in
{
  options.plusultra.containers.recyclarr = with types; {
    enable = mkBoolOpt false "Whether or not to enable recyclarr.";
  };

  config = mkIf cfg.enable {
    systemd.services.recyclarr.serviceConfig.LoadCredential = [
      "sonarr-api_key:${config.age.secrets.sonarr-api.path}"
    ];
    services.recyclarr = {
      enable = true;
      configuration = {
        sonarr = {
          web-2160p-v4 = {
            base_url = "http://haruka:8989/";
            api_key = {
              _secret = "/run/credentials/recyclarr.service/sonarr-api_key";
            };

            include = [
              { template = "sonarr-quality-definition-series"; }
              { template = "sonarr-v4-quality-profile-web-2160p"; }
              { template = "sonarr-v4-custom-formats-web-2160p"; }
            ];

            custom_formats = [
              # HDR Formats
              {
                trash_ids = [
                  "9b27ab6498ec0f31a3353992e19434ca" # DV (WEBDL)
                ];
                assign_scores_to = [
                  { name = "WEB-2160p"; }
                ];
              }
              {
                trash_ids = [
                  "32b367365729d530ca1c124a0b180c64" # Bad Dual Groups
                  "82d40da2bc6923f41e14394075dd4b03" # No-RlsGroup
                  "e1a997ddb54e3ecbfe06341ad323c458" # Obfuscated
                  "06d66ab109d4d2eddb2794d21526d140" # Retags
                  # "1b3994c551cbb92a2c781af061f4ab44" # Scene
                ];
                assign_scores_to = [
                  { name = "WEB-2160p"; }
                ];
              }
              # Allow x265 HD releases with HDR/DV
              {
                trash_ids = [
                  "47435ece6b99a0b477caf360e79ba0bb" # x265 (HD)
                ];
                assign_scores_to = [
                  {
                    name = "WEB-2160p";
                    score = 0;
                  }
                ];
              }
              # Allow x265 HD releases with HDR/DV
              {
                trash_ids = [
                  "9b64dff695c2115facf1b6ea59c9bd07" # x265 (no HDR/DV)
                ];
                assign_scores_to = [
                  { name = "WEB-2160p"; }
                ];
              }
              # Optional SDR
              # Only ever use ONE of the following custom formats:
              # SDR - block ALL SDR releases
              # SDR (no WEBDL) - block UHD/4k Remux and Bluray encode SDR releases, but allow SDR WEB#
              {
                trash_ids = [
                  "2016d1676f5ee13a5b7257ff86ac9a93"
                ];
                assign_scores_to = [
                  { name = "WEB-2160p"; }
                ];
              }
            ];
          };
        };
      };
    };
  };
}
