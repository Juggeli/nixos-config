inputs@{ options, config, lib, pkgs, ... }:

with lib;
with lib.internal;
let
  cfg = config.plusultra.apps.pdf;
in
{
  options.plusultra.apps.pdf = with types; {
    enable = mkBoolOpt false "Whether or not to enable Zathura and pdftotext.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      zathura
      poppler_utils
    ];
  };
}

