{ config, lib, pkgs, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.cli-apps.lazygit;
in
{
  options.plusultra.cli-apps.lazygit = with types; {
    enable = mkBoolOpt false "Whether or not to enable lazygit.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      lazygit
    ];
    plusultra.user.impermanence.files = [
      ".config/lazygit/state.yml"
    ];
  };
}
