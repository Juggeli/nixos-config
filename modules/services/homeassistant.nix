{ options, inputs, config, lib, pkgs, ... }:

with lib;
with lib.my;
let
  cfg = config.modules.services.homeassistant;
  mkLovelaceModule = name: {
    url = "/local/${name}.js?${pkgs.nur.repos.mweinelt.hassLovelaceModules."${name}".version}";
    type = "module";
  };
in
{
  options.modules.services.homeassistant = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    nixpkgs.overlays = [ inputs.nur.overlay ];

    environment.systemPackages = [
      pkgs.cloudflared
    ];

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
        default_config = { };
        http = {
          server_host = "::1";
          trusted_proxies = [ "::1" ];
          use_x_forwarded_for = true;
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d /run/hass 0700 nginx nginx"
      "L+ /run/hass/apexcharts-card.js - - - - ${pkgs.nur.repos.mweinelt.hassLovelaceModules.apexcharts-card}/apexcharts-card.js"
      "L+ /run/hass/mushroom.js - - - - ${pkgs.nur.repos.mweinelt.hassLovelaceModules.mushroom}/mushroom.js"
    ];

    services.home-assistant.config.lovelace = {
      resources = [
        (mkLovelaceModule "apexcharts-card")
        (mkLovelaceModule "mushroom")
      ];
    };

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      virtualHosts."hass.jugi.cc" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = ''
          proxy_buffering off;
        '';
        locations."/" = {
          proxyPass = "http://[::1]:8123";
          proxyWebsockets = true;
        };
        locations."/local/" = {
          alias = "/run/hass/";
        };
      };
    };
    security.acme.defaults.email = "juggeli@gmail.com";

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
      enable = false;
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

    users.users.cloudflared = {
      group = "cloudflared";
      isSystemUser = true;
    };
    users.groups.cloudflared = { };

    systemd.services.cloudflare-tunnel = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "systemd-resolved.service" ];
      serviceConfig = {
        ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token=eyJhIjoiMTMyMjkxYzEyNmQ1MTBjZDg1N2VkZGMzNjdhMmM3N2EiLCJ0IjoiMmM0NDc1ZTEtNzdlNC00NmJkLWFhYmUtNDJhMjY1Y2VjNWZkIiwicyI6Ik1ETmpNMkptWmpndE5EQmtZUzAwWXpNMExXRXpaVEF0TURjM01HRTNORFEzTXpSbSJ9";
        Restart = "always";
        User = "cloudflared";
        Group = "cloudflared";
      };
    };
  };
}

