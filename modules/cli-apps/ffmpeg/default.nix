inputs@{ options, config, lib, pkgs, ... }:

with lib;
with lib.internal;
let
  cfg = config.plusultra.cli-apps.ffmpeg;
in
{
  options.plusultra.cli-apps.ffmpeg = with types; {
    enable = mkBoolOpt false "Whether or not to enable ffmpeg.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      ffmpeg_5-full
      mkvtoolnix
    ];
  };
}
