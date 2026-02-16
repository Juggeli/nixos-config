{
  config,
  lib,
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
      "sonarr-anime-api_key:${config.age.secrets.sonarr-anime-api.path}"
    ];
    services.recyclarr = {
      enable = true;
      configuration = {
        sonarr = {
          anime-sonarr-v4 = {
            base_url = "http://haruka:8999";
            api_key = {
              _secret = "/run/credentials/recyclarr.service/sonarr-anime-api_key";
            };

            include = [
              { template = "sonarr-quality-definition-anime"; }
              { template = "sonarr-v4-custom-formats-anime"; }
            ];

            quality_profiles = [
              {
                name = "Remux-1080p - Anime";
                reset_unmatched_scores = {
                  enabled = true;
                };
                upgrade = {
                  allowed = true;
                  until_quality = "1080p";
                  until_score = 10000;
                };
                min_format_score = 100;
                score_set = "anime-sonarr";
                quality_sort = "top";
                qualities = [
                  {
                    name = "1080p";
                    qualities = [
                      "Bluray-1080p"
                      "WEBDL-1080p"
                      "WEBRip-1080p"
                      "HDTV-1080p"
                    ];
                  }
                  {
                    name = "Bluray-720p";
                  }
                  {
                    name = "WEB 720p";
                    qualities = [
                      "WEBDL-720p"
                      "WEBRip-720p"
                      "HDTV-720p"
                    ];
                  }
                  {
                    name = "Bluray-480p";
                  }
                  {
                    name = "WEB 480p";
                    qualities = [
                      "WEBDL-480p"
                      "WEBRip-480p"
                    ];
                  }
                  {
                    name = "DVD";
                  }
                  {
                    name = "SDTV";
                  }
                ];
              }
            ];

            custom_formats = [
              {
                trash_ids = [
                  "026d5aadd1a6b4e550b134cb6c72b3ca" # Uncensored
                ];
                assign_scores_to = [
                  {
                    name = "Remux-1080p - Anime";
                    score = 2000;
                  }
                ];
              }
              {
                trash_ids = [
                  "b2550eb333d27b75833e25b8c2557b38" # 10bit
                ];
                assign_scores_to = [
                  {
                    name = "Remux-1080p - Anime";
                    score = 10;
                  }
                ];
              }
            ];
          };

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

            quality_profiles = [
              {
                name = "WEB-2160p";
                upgrade = {
                  allowed = true;
                  until_quality = "WEB 2160p";
                  until_score = 10000;
                };
                min_format_score = 0;
                quality_sort = "top";
                qualities = [
                  {
                    name = "WEB 2160p";
                    qualities = [
                      "WEBDL-2160p"
                      "WEBRip-2160p"
                    ];
                  }
                  {
                    name = "WEB 1080p";
                    qualities = [
                      "WEBDL-1080p"
                      "WEBRip-1080p"
                    ];
                  }
                ];
              }
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
              # Block SDR for UHD/4k Remux and Bluray but allow SDR WEB releases as fallback
              {
                trash_ids = [
                  "83304f261cf516bb208c18c54c0adf97" # SDR (no WEBDL)
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
