{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.plusultra.cli-apps.neovim;
in
{
  options.plusultra.cli-apps.neovim = {
    enable = mkEnableOption "Neovim";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      nvim-pkg
    ];

    plusultra.user.impermanence = {
      directories = [
        ".local/state/nvim"
        ".local/share/nvim"
        ".cache/nvim"
      ];
    };
  };
}
