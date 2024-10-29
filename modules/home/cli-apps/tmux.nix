{
  config,
  lib,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.cli-apps.tmux;
in
{
  options.plusultra.cli-apps.tmux = with types; {
    enable = mkBoolOpt false "Whether or not to enable tmux.";
  };

  config = mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      catppuccin.enable = true;
    };
  };
}
