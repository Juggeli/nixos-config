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
      (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
      ubuntu_font_family
      font-awesome
      my.comic-code
    ];

    fonts.fontconfig.defaultFonts = {
      sansSerif = [ "Ubuntu" ];
      monospace = [ "Comic Code Ligatures" ];
    };
  };
}



