{
  lib,
  config,
  pkgs,
  inputs,
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
      inputs.neovim.packages.${pkgs.system}.nvim
    ];

    home.sessionVariables = {
      EDITOR = "nvim";
    };

    plusultra.user.impermanence = {
      directories = [
        ".local/state/nvim"
        ".local/share/nvim"
        ".cache/nvim"
        ".config/github-copilot"
      ];
    };
  };
}
