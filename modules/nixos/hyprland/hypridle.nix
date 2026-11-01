{
  flake.nixosModules.hypridle =
    { config, pkgs, ... }:
    let
      hyprctl = "${config.programs.hyprland.package}/bin/hyprctl";
      mediaPlaying = "${pkgs.playerctl}/bin/playerctl --all-players status 2>/dev/null | grep -q Playing";

      waitLock = pkgs.writeShellScriptBin "wait-lock" ''
        #!/usr/bin/env bash
        CHECK_INTERVAL=5
        trap 'exit 0' INT TERM

        while ${mediaPlaying}; do
            sleep "$CHECK_INTERVAL"
        done

        loginctl lock-session
      '';

      waitDpmsOff = pkgs.writeShellScriptBin "wait-dpms-off" ''
        #!/usr/bin/env bash
        CHECK_INTERVAL=5
        trap 'exit 0' INT TERM

        while ${mediaPlaying}; do
            sleep "$CHECK_INTERVAL"
        done

        ${hyprctl} dispatch dpms off
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

        while ${mediaPlaying}; do
            sleep "$CHECK_INTERVAL"
        done

        systemctl suspend
      '';
    in
    {
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

      home-manager.users.juggeli.services.hypridle = {
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
            # hypridle drops resume events for listeners while a D-Bus or
            # systemd inhibitor (e.g. a playing video) is held, which would
            # leave the pending idle actions armed. This listener ignores
            # inhibitors so any input always cancels them; its timeout only
            # needs to be shorter than the action timeouts below.
            {
              timeout = 60;
              ignore_inhibit = true;
              on-resume = "systemctl --user stop idle-wait-lock.service idle-wait-dpms-off.service idle-wait-suspend.service; ${hyprctl} dispatch dpms on";
            }
            {
              timeout = 300;
              on-timeout = "systemctl --user start idle-wait-lock.service";
            }
            {
              timeout = 360;
              on-timeout = "systemctl --user start idle-wait-dpms-off.service";
            }
            {
              timeout = 1800;
              on-timeout = "systemctl --user start idle-wait-suspend.service";
            }
          ];
        };
      };
    };
}
