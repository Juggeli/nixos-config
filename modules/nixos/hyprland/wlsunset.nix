{
  flake.nixosModules.wlsunset =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.wlsunset ];

      systemd.user.services.wlsunset = {
        description = "Blue light filter for Wayland";
        after = [ "hyprland-session.target" ];
        partOf = [ "hyprland-session.target" ];
        wantedBy = [ "hyprland-session.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.wlsunset}/bin/wlsunset -t 4000 -T 6500 -d 900 -S 08:00 -s 22:00";
          Restart = "always";
          RestartSec = 3;
        };
      };
    };
}
