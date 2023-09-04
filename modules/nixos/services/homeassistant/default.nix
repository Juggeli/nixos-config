{ options, config, pkgs, lib, inputs, ... }:

with lib;
with lib.internal;
let
  cfg = config.plusultra.services.homeassistant;
in
{
  options.plusultra.services.homeassistant = with types; {
    enable = mkBoolOpt false "Whether or not to enable homeassistant service.";
  };

  config = mkIf cfg.enable {
    nixpkgs.overlays = [ inputs.nur.overlay ];

    services.home-assistant = {
      enable = true;
      configDir = "/mnt/appdata/home-assistant";
      package = (pkgs.home-assistant.override {
        extraPackages = py: with py; [ psycopg2 ];
      }).overrideAttrs (old: {
        doInstallCheck = false;
        patches = (old.patches or [ ]) ++ [
          ./static-symlinks.patch
        ];
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
        "broadlink"
        "thread"
        "google_translate"
      ];
      config = {
        default_config = { };
        homeassistant = {
          name = "Home";
          latitude = "!secret latitude";
          longitude = "!secret longitude";
          elevation = "!secret elevation";
          unit_system = "metric";
          temperature_unit = "C";
          time_zone = "Europe/Helsinki";
        };
        http = {
          server_host = "10.11.11.2";
          trusted_proxies = [ "10.11.11.2" ];
          use_x_forwarded_for = true;
        };
        mqtt = { };
        yeelight = { };
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/hass/www 0755 hass hass"
      "L /var/lib/hass/www/apexcharts-card.js - - - - ${pkgs.nur.repos.mweinelt.hassLovelaceModules.apexcharts-card}/apexcharts-card.js"
      "L /var/lib/hass/www/mushroom.js - - - - ${pkgs.nur.repos.mweinelt.hassLovelaceModules.mushroom}/mushroom.js"
    ];

    services.home-assistant.config.lovelace.resources = [
      { url = "local/apexcharts-card.js"; type = "module"; }
      { url = "local/mushroom.js"; type = "module"; }
    ];

    services.postgresql = {
      enable = true;
      dataDir = "/mnt/appdata/postgresql";
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
      dataDir = "/mnt/appdata/zigbee2mqtt";
      settings = {
        homeassistant = true;
        mqtt = {
          server = "mqtt://localhost:1883";
        };
        serial = {
          port = "/dev/ttyUSB0";
        };
        frontend = {
          port = 8090;
          host = "10.11.11.2";
        };
        advanced = {
          channel = 25;
          pan_id = 6754;
        };
        groups = "groups.yaml";
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ 8123 8090 1400 ];
      allowedUDPPorts = [ 5353 ];
    };
  };
}
