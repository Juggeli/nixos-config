{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.desktop.addons.mako;
in
{
  options.plusultra.desktop.addons.mako = with types; {
    enable = mkBoolOpt false "Whether to enable Mako in Sway.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      mako
      libnotify
    ];

    systemd.user.services.mako = {
      description = "Mako notification daemon";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "dbus";
        BusName = "org.freedesktop.Notifications";

        ExecCondition = ''
          ${pkgs.bash}/bin/bash -c '[ -n "$WAYLAND_DISPLAY" ]'
        '';

        ExecStart = ''
          ${pkgs.mako}/bin/mako
        '';

        ExecReload = ''
          ${pkgs.mako}/bin/makoctl reload
        '';

        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };

    plusultra.home.configFile."mako/config".text = ''
      font=Hack Nerd Font Mono 10
      anchor=bottom-center
      border-radius=8
      text-color=#2e3440ff
      background-color=#eceff4f4
      border-color=#d8dee9ff
      border-size=0
      margin=12,12,6
      padding=12,12,12,12
      default-timeout=5000
      max-visible=3
    '';
  };
}
