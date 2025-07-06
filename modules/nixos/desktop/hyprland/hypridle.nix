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

  waitSuspend = pkgs.writeShellScriptBin "wait-suspend" ''
    #!/usr/bin/env bash
    CHECK_INTERVAL=5
    trap 'exit 0' INT TERM          # quit cleanly if hypridle kills us

    while busctl get-property \
            org.freedesktop.login1 /org/freedesktop/login1 \
            org.freedesktop.login1.Manager BlockInhibited |
          grep -q sleep; do
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
      waitSuspend
    ];

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
            on-timeout = "hyprlock";
            on-resume = "${pkgs.doas}/bin/doas ${pkgs.kmod}/bin/modprobe -r hid-logitech-hidpp hid-logitech-dj && sleep 2 && ${pkgs.doas}/bin/doas ${pkgs.kmod}/bin/modprobe hid-logitech-dj hid-logitech-hidpp";
          }
          {
            timeout = 360;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
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
