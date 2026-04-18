{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.desktop.hyprland.wlsunset;
in
{
  options.plusultra.desktop.hyprland.wlsunset = with types; {
    enable = mkBoolOpt false "Whether or not to enable blue light filter.";
    temperature = mkOpt int 4000 "Color temperature for night mode.";
    high-temperature = mkOpt int 6500 "Color temperature for day mode.";
    duration = mkOpt int 900 "Transition duration in seconds.";
    sunrise-time = mkOpt str "08:00" "Time to restore normal color temperature.";
    sunset-time = mkOpt str "22:00" "Time to reduce blue light.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      wlsunset
    ];

    systemd.user.services.wlsunset = {
      description = "Blue light filter for Wayland";
      after = [ "hyprland-session.target" ];
      partOf = [ "hyprland-session.target" ];
      wantedBy = [ "hyprland-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.wlsunset}/bin/wlsunset -t ${toString cfg.temperature} -T ${toString cfg.high-temperature} -d ${toString cfg.duration} -S ${cfg.sunrise-time} -s ${cfg.sunset-time}";
        Restart = "always";
        RestartSec = 3;
      };
    };
  };
}
