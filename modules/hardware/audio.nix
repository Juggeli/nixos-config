
{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.hardware.audio;
  configDir = config.dotfiles.configDir;
in {
  options.modules.hardware.audio = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hardware.pulseaudio.enable = false;

    services.pipewire = {
      enable = true;
      wireplumber.enable = true;
      
      alsa.enable = true;
      pulse.enable = true;
      jack.enable = false;
    };

    security.rtkit.enable = true;

    environment.systemPackages = with pkgs; [
      pavucontrol
      pulseaudio
    ];

    user.extraGroups = [ "audio" ];

    environment.etc = {
      "wireplumber" = { source = "${configDir}/wireplumber"; };
    };
  };
}