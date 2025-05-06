{
  config,
  lib,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.cli-apps.lazygit;
in
{
  options.plusultra.cli-apps.lazygit = with types; {
    enable = mkBoolOpt false "Whether or not to enable lazygit.";
  };

  config = mkIf cfg.enable {
    programs.lazygit = {
      enable = true;
      settings = {
        gui = {
          nerdFontsVersion = "3";
        };
        git.paging.pager = "delta --dark --paging=never";
      };
    };
    catppuccin.lazygit.enable = true;

    plusultra.user.impermanence.files = [
      ".config/lazygit/state.yml"
    ];
  };
}
