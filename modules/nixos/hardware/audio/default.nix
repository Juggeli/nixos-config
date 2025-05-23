{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.hardware.audio;
in
{
  options.plusultra.hardware.audio = with types; {
    enable = mkBoolOpt false "Whether or not to enable audio support.";
    alsa-monitor = mkOpt attrs { } "Alsa configuration.";
    nodes = mkOpt (listOf attrs) [ ] "Audio nodes to pass to Pipewire as `context.objects`.";
    modules = mkOpt (listOf attrs) [ ] "Audio modules to pass to Pipewire as `context.modules`.";
    extra-packages = mkOpt (listOf package) [
      pkgs.qjackctl
      pkgs.easyeffects
    ] "Additional packages to install.";
  };

  config = mkIf cfg.enable {
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      jack.enable = true;

      wireplumber.enable = true;
    };

    environment.systemPackages =
      with pkgs;
      [
        pulsemixer
        pavucontrol
      ]
      ++ cfg.extra-packages;

    plusultra.user.extraGroups = [ "audio" ];

    plusultra.home.extraOptions = {
      systemd.user.services.mpris-proxy = {
        Unit.Description = "Mpris proxy";
        Unit.After = [
          "network.target"
          "sound.target"
        ];
        Service.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
        Install.WantedBy = [ "default.target" ];
      };
    };
  };
}
