{ lib, config, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.plusultra.cli-apps.neovim;
in
{
  options.plusultra.cli-apps.neovim = {
    enable = mkEnableOption "Neovim";
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        less
        plusultra.neovim
      ];

      sessionVariables = {
        PAGER = "less";
        MANPAGER = "less";
        EDITOR = "nvim";
      };

      shellAliases = {
        vimdiff = "nvim -d";
      };
    };
  };
}