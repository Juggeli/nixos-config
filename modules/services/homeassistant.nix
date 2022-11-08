{ options, inputs, config, lib, pkgs, ... }:

with lib;
with lib.my;
let
  cfg = config.modules.services.homeassistant;
in
{
  options.modules.services.homeassistant = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    nixpkgs.overlays = [ inputs.nur.overlay ];

    services.home-assistant = {
      enable = true;
      package = (pkgs.home-assistant.override {
        extraPackages = py: with py; [ psycopg2 ];
      }).overrideAttrs (oldAttrs: {
        doInstallCheck = false;
      });
      config.recorder.db_url = "postgresql://@/hass";
      extraComponents = [
        # Components required to complete the onboarding
        "met"
        "radio_browser"
        "apple_tv"
        "brother"
        "yeelight"
        "tasmota"
        "mqtt"
        "sonos"
        "ios"
        "ffmpeg"
        "backup"
        "webostv"
        "xiaomi"
        "xiaomi_miio"
        "xiaomi_aqara"
        "zha"
        "homekit"
        "ipp"
      ];
      config = {
        # Includes dependencies for a basic setup
        # https://www.home-assistant.io/integrations/default_config/
        default_config = { };
      };
    };

    # Custom Lovelace Modules
    systemd.tmpfiles.rules = [
      "d /var/lib/hass/www 0755 hass hass"
      "L /var/lib/hass/www/apexcharts-card.js - - - - ${pkgs.nur.repos.mweinelt.hassLovelaceModules.apexcharts-card}/apexcharts-card.js"
      "L /var/lib/hass/www/mushroom.js - - - - ${pkgs.nur.repos.mweinelt.hassLovelaceModules.mushroom}/mushroom.js"
    ];

    services.home-assistant.lovelaceConfig.resources = [
      {
        url = "local/apexcharts-card.js";
        type = "module";
      }
      {
        url = "local/mushroom.js";
        type = "module";
      }
    ];

    services.postgresql = {
      enable = true;
      ensureDatabases = [ "hass" ];
      ensureUsers = [{
        name = "hass";
        ensurePermissions = {
          "DATABASE hass" = "ALL PRIVILEGES";
        };
      }];
    };

    services.mosquitto = {
      enable = true;
      listeners = [{
        acl = [ "pattern readwrite #" ];
        omitPasswordAuth = true;
        settings.allow_anonymous = true;
      }];
    };

    services.zigbee2mqtt = {
      enable = true;
      dataDir = "/mnt/pool/appdata/zigbee2mqtt";
      settings = {
        homeassistant = config.services.home-assistant.enable;
        serial = {
          port = "/dev/ttyUSB0";
        };
        frontend = {
          port = 8090;
          host = "10.11.11.2";
        };
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ config.services.home-assistant.config.http.server_port 8090 ];
    };
  };
}

