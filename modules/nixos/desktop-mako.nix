{
  flake.nixosModules.desktop-mako =
    { pkgs, ... }:
    {
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

          ExecStart = "${pkgs.mako}/bin/mako";
          ExecReload = "${pkgs.mako}/bin/makoctl reload";

          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
      };

      home-manager.users.juggeli.xdg.configFile."mako/config".text = ''
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
