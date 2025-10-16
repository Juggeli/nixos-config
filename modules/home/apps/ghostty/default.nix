{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.apps.ghostty;

  ghosttyPackage = if pkgs.stdenv.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
in
{
  options.plusultra.apps.ghostty = with types; {
    enable = mkBoolOpt false "Whether or not to enable ghostty.";
    fontSize = mkOpt types.int 14 "Font size to use with ghostty.";
  };

  config = mkIf cfg.enable {
    home.packages = [
      ghosttyPackage
    ];

    xdg.configFile."ghostty/config" = {
      text = ''
        font-family = Comic Code Ligatures
        font-size = ${toString cfg.fontSize}

        command = ${pkgs.fish}/bin/fish

        window-decoration = false
        window-padding-x = 4
        window-padding-y = 4

        confirm-close-surface = false

        theme = Catppuccin Mocha
      '';
    };
  };
}
