{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.tools.hdd-scraper;
in
{
  options.plusultra.tools.hdd-scraper = with types; {
    enable = mkBoolOpt false "Whether or not to enable HDD price scraper tool.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      plusultra.hdd-scraper
    ];
  };
}
