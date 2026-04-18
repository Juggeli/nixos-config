{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.desktop.hyprland.hypridle;

  waitLock = pkgs.writeShellScriptBin "wait-lock" ''
    #!/usr/bin/env bash
    CHECK_INTERVAL=5
    trap 'exit 0' INT TERM

    while ${pkgs.playerctl}/bin/playerctl status 2>/dev/null | grep -q Playing; do
        sleep "$CHECK_INTERVAL"
    done

    pidof hyprlock || hyprlock -q
  '';

  waitDpmsOff = pkgs.writeShellScriptBin "wait-dpms-off" ''
    #!/usr/bin/env bash
    CHECK_INTERVAL=5
    trap 'exit 0' INT TERM

    while ${pkgs.playerctl}/bin/playerctl status 2>/dev/null | grep -q Playing; do
        sleep "$CHECK_INTERVAL"
    done

    hyprctl dispatch dpms off
  '';

  waitSuspend = pkgs.writeShellScriptBin "wait-suspend" ''
    #!/usr/bin/env bash
    CHECK_INTERVAL=5
    trap 'exit 0' INT TERM

    while busctl get-property \
            org.freedesktop.login1 /org/freedesktop/login1 \
            org.freedesktop.login1.Manager BlockInhibited |
          grep -q sleep; do
        sleep "$CHECK_INTERVAL"
    done

    while ${pkgs.playerctl}/bin/playerctl status 2>/dev/null | grep -q Playing; do
        sleep "$CHECK_INTERVAL"
    done

    systemctl suspend
  '';
in
{
  options.plusultra.desktop.hyprland.hypridle = with types; {
    enable = mkBoolOpt false "Whether or not to enable hypridle.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      playerctl
      waitLock
      waitDpmsOff
      waitSuspend
    ];

    systemd.user.services.idle-wait-lock = {
      description = "Wait until media stops, then lock";
      serviceConfig = {
        ExecStart = "${waitLock}/bin/wait-lock";
        KillMode = "mixed";
        Type = "simple";
      };
    };

    systemd.user.services.idle-wait-dpms-off = {
      description = "Wait until media stops, then turn off display";
      serviceConfig = {
        ExecStart = "${waitDpmsOff}/bin/wait-dpms-off";
        KillMode = "mixed";
        Type = "simple";
      };
    };

    systemd.user.services.idle-wait-suspend = {
      description = "Wait until block inhibitors clear, then suspend";
      serviceConfig = {
        ExecStart = "${waitSuspend}/bin/wait-suspend";
        KillMode = "mixed";
        Type = "simple";
      };
    };

    plusultra.home.extraOptions.services.hypridle = {
      enable = true;
      settings = {
        general = {
          before_sleep_cmd = "loginctl lock-session & playerctl pause";
          after_sleep_cmd = "hyprctl dispatch dpms on";
          ignore_dbus_inhibit = false;
          ignore_systemd_inhibit = false;
          lock_cmd = "pidof hyprlock || hyprlock -q";
        };
        listener = [
          {
            timeout = 300;
            on-timeout = "systemctl --user start idle-wait-lock.service";
            on-resume = "systemctl --user stop idle-wait-lock.service";
          }
          {
            timeout = 360;
            on-timeout = "systemctl --user start idle-wait-dpms-off.service";
            on-resume = "systemctl --user stop idle-wait-dpms-off.service && hyprctl dispatch dpms on";
          }
          {
            timeout = 1800;
            on-timeout = "systemctl --user start idle-wait-suspend.service";
            on-resume = "systemctl --user stop idle-wait-suspend.service";
          }
        ];
      };
    };
  };
}
