{ options, config, pkgs, lib, ... }:
with lib;
with lib.my;
let cfg = config.modules.desktop.fonts;
in
{
  options.modules.desktop.fonts = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    fonts.fonts = with pkgs; [
      fira-code
      fira-code-symbols
      fira
      font-awesome
      my.comic-code
    ];

    fonts.fontconfig.defaultFonts = {
      sansSerif = [ "Fira Sans" ];
      monospace = [ "ComicCodeLigatures Nerd Font" ];
    };
  };
}



