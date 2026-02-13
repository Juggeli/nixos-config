{
  config,
  lib,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.cli-apps.gh;
in
{
  options.plusultra.cli-apps.gh = with types; {
    enable = mkBoolOpt false "Whether or not to enable GitHub CLI.";
  };

  config = mkIf cfg.enable {
    programs.gh = {
      enable = true;
      settings = {
        git_protocol = "ssh";
      };
    };

    xdg.configFile."gh/config.yml".force = true;
  };
}
