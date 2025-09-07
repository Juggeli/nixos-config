{ config, lib, ... }:

with lib;
with lib.plusultra;
let
  cfg = config.plusultra.services.homepage;

  # Extract services with homepage metadata from containers
  homepageServices = lib.filterAttrs (
    name: value: value ? homepage && value.enable or false
  ) config.plusultra.containers;

  # Group services by category
  servicesByCategory = lib.groupBy (service: service.homepage.category) (
    lib.mapAttrsToList (name: value: value // { _name = name; }) homepageServices
  );

  # Generate service entries for a category
  generateServiceEntries =
    category: services:
    map (service: {
      "${service.homepage.name}" = {
        icon = service.homepage.icon;
        description = service.homepage.description or "";
        href =
          if service.homepage ? url && service.homepage.url != null then
            service.homepage.url
          else
            "http://${config.networking.hostName}:${toString service.homepage.port}";
        siteMonitor =
          if service.homepage ? url && service.homepage.url != null then
            service.homepage.url
          else
            "http://${config.networking.hostName}:${toString service.homepage.port}";
      }
      // lib.optionalAttrs (service.homepage ? widget && service.homepage.widget.enable) {
        widget = {
          type = if service.homepage.widget ? type then service.homepage.widget.type else service._name;
          url =
            if service.homepage ? url && service.homepage.url != null then
              service.homepage.url
            else
              "http://${config.networking.hostName}:${toString service.homepage.port}";
          key = "{{HOMEPAGE_VAR_${lib.toUpper (lib.replaceStrings [ "-" ] [ "_" ] service._name)}_API_KEY}}";
        }
        // lib.optionalAttrs (service.homepage.widget ? fields) {
          fields = service.homepage.widget.fields;
        }
        // lib.optionalAttrs (service.homepage.widget ? enableBlocks) {
          enableBlocks = service.homepage.widget.enableBlocks;
        }
        // lib.optionalAttrs (service.homepage.widget ? slug) {
          slug = service.homepage.widget.slug;
        };
      };
    }) services;

  # Generate misc service entries with widget support
  generateMiscServiceEntries =
    miscServices:
    map (
      serviceSet:
      lib.mapAttrs (
        name: service:
        {
          inherit (service)
            description
            href
            siteMonitor
            icon
            ;
        }
        // lib.optionalAttrs (service.widget != null) {
          widget = {
            inherit (service.widget) type url;
          }
          // lib.optionalAttrs (service.widget.key != null) {
            key = service.widget.key;
          }
          // lib.optionalAttrs (service.widget.username != null) {
            username = service.widget.username;
          }
          // lib.optionalAttrs (service.widget.password != null) {
            password = service.widget.password;
          }
          // lib.optionalAttrs (service.widget.fields != null) {
            fields = service.widget.fields;
          }
          // lib.optionalAttrs (service.widget.enableBlocks != null) {
            enableBlocks = service.widget.enableBlocks;
          }
          // lib.optionalAttrs (service.widget.enableNowPlaying != null) {
            enableNowPlaying = service.widget.enableNowPlaying;
          }
          // lib.optionalAttrs (service.widget.slug != null) {
            slug = service.widget.slug;
          };
        }
      ) serviceSet
    ) miscServices;
in
{
  options.plusultra.services.homepage = with types; {
    enable = mkBoolOpt false "Whether or not to enable homepage dashboard service.";

    misc = mkOption {
      default = [ ];
      type = listOf (
        attrsOf (submodule {
          options = {
            description = mkOption {
              type = str;
              description = "Service description";
            };
            href = mkOption {
              type = str;
              description = "Service URL";
            };
            siteMonitor = mkOption {
              type = str;
              description = "URL for site monitoring";
            };
            icon = mkOption {
              type = str;
              description = "Icon for the service";
            };
            widget = mkOption {
              type = nullOr (submodule {
                options = {
                  type = mkOption {
                    type = str;
                    description = "Widget type";
                  };
                  url = mkOption {
                    type = str;
                    description = "Widget URL";
                  };
                  key = mkOption {
                    type = nullOr str;
                    default = null;
                    description = "API key for the widget";
                  };
                  username = mkOption {
                    type = nullOr str;
                    default = null;
                    description = "Username for authentication";
                  };
                  password = mkOption {
                    type = nullOr str;
                    default = null;
                    description = "Password for authentication";
                  };
                  fields = mkOption {
                    type = nullOr (listOf str);
                    default = null;
                    description = "Widget fields to display";
                  };
                  enableBlocks = mkOption {
                    type = nullOr bool;
                    default = null;
                    description = "Enable blocks in widget";
                  };
                  enableNowPlaying = mkOption {
                    type = nullOr bool;
                    default = null;
                    description = "Enable now playing in widget";
                  };
                  slug = mkOption {
                    type = nullOr str;
                    default = null;
                    description = "Widget slug";
                  };
                };
              });
              default = null;
              description = "Widget configuration for the service";
            };
          };
        })
      );
      description = "Additional miscellaneous services to display";
    };
  };

  config = mkIf cfg.enable {
    services.glances.enable = true;

    services.homepage-dashboard = {
      enable = true;
      openFirewall = true;
      listenPort = 3000;

      customCSS = ''
        body, html {
          font-family: SF Pro Display, Helvetica, Arial, sans-serif !important;
        }
        .font-medium {
          font-weight: 700 !important;
        }
        .font-light {
          font-weight: 500 !important;
        }
        .font-thin {
          font-weight: 400 !important;
        }
        #information-widgets {
          padding-left: 1.5rem;
          padding-right: 1.5rem;
        }
        div#footer {
          display: none;
        }
        .services-group.basis-full.flex-1.px-1.-my-1 {
          padding-bottom: 3rem;
        }
      '';

      settings = {
        layout = [
          {
            System = {
              header = false;
              style = "row";
              columns = 4;
            };
          }
        ]
        ++ (map (category: {
          "${category}" = {
            header = true;
            style = "column";
          };
        }) (lib.attrNames servicesByCategory))
        ++ [
          {
            Ultra = {
              header = true;
              style = "column";
            };
          }
        ];
        headerStyle = "clean";
        statusStyle = "dot";
        hideVersion = true;
      };

      environmentFile = config.age.secrets.homepage-env.path;

      services =
        # Dynamic service categories
        (map (category: {
          "${category}" = generateServiceEntries category servicesByCategory.${category};
        }) (lib.attrNames servicesByCategory))
        # Misc services
        ++ lib.optional (cfg.misc != [ ]) { Ultra = generateMiscServiceEntries cfg.misc; }
        # System monitoring
        ++ [
          {
            System =
              let
                port = toString config.services.glances.port;
              in
              [
                {
                  Info = {
                    widget = {
                      type = "glances";
                      url = "http://localhost:${port}";
                      metric = "info";
                      chart = false;
                      version = 4;
                    };
                  };
                }
                {
                  "CPU Temp" = {
                    widget = {
                      type = "glances";
                      url = "http://localhost:${port}";
                      metric = "sensor:Package id 0";
                      chart = false;
                      version = 4;
                    };
                  };
                }
                {
                  Processes = {
                    widget = {
                      type = "glances";
                      url = "http://localhost:${port}";
                      metric = "process";
                      chart = false;
                      version = 4;
                    };
                  };
                }
                {
                  Network = {
                    widget = {
                      type = "glances";
                      url = "http://localhost:${port}";
                      metric = "network:enp1s0";
                      chart = false;
                      version = 4;
                    };
                  };
                }
                {
                  "tank/backup" = {
                    widget = {
                      type = "glances";
                      url = "http://localhost:${port}";
                      metric = "fs:/tank/backup";
                      chart = false;
                      version = 4;
                      diskUnits = "bytes";
                    };
                  };
                }
                {
                  "tank/documents" = {
                    widget = {
                      type = "glances";
                      url = "http://localhost:${port}";
                      metric = "fs:/tank/documents";
                      chart = false;
                      version = 4;
                      diskUnits = "bytes";
                    };
                  };
                }
                {
                  "tank/media" = {
                    widget = {
                      type = "glances";
                      url = "http://localhost:${port}";
                      metric = "fs:/tank/media";
                      chart = false;
                      version = 4;
                      diskUnits = "bytes";
                    };
                  };
                }
                {
                  "tank/sorted" = {
                    widget = {
                      type = "glances";
                      url = "http://localhost:${port}";
                      metric = "fs:/tank/sorted";
                      chart = false;
                      version = 4;
                      diskUnits = "bytes";
                    };
                  };
                }
              ];
          }
        ];
    };
  };
}
