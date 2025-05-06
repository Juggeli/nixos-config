{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.apps.pdf;
in
{
  options.plusultra.apps.pdf = with types; {
    enable = mkBoolOpt false "Whether or not to enable Zathura and pdftotext.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      poppler_utils
    ];

    programs.zathura = {
      enable = true;
    };
    catppuccin.zathura.enable = true;
  };
}
