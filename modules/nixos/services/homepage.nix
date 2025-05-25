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
      "${service.homepage.name}" =
        {
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
          widget =
            {
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
        layout =
          [
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
              Misc = {
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
        ++ lib.optional (cfg.misc != [ ]) { Misc = cfg.misc; }
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
              ];
          }
        ];
    };

  };
}
