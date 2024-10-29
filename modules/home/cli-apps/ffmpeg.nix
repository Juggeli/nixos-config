{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.cli-apps.ffmpeg;
in
{
  options.plusultra.cli-apps.ffmpeg = with types; {
    enable = mkBoolOpt false "Whether or not to enable ffmpeg.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      (ffmpeg-headless.override { withVmaf = true; })
      mkvtoolnix
      makemkv
    ];
  };
}
