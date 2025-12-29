{
  config,
  lib,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.cli-apps.nh;
in
{
  options.plusultra.cli-apps.nh = with types; {
    enable = mkBoolOpt false "Whether or not to enable nh.";
  };

  config = mkIf cfg.enable {
    programs.nh = {
      enable = true;
      flake = "${config.home.homeDirectory}/src/dotfiles";
      clean.enable = true;
    };
  };
}
