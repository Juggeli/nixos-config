{ config, lib, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.apps.kitty;
in
{
  options.plusultra.apps.kitty = with types; {
    enable = mkBoolOpt false "Whether or not to enable kitty.";
    fontSize = mkOpt types.int 13 "Font size to use with kitty.";
  };

  config = mkIf cfg.enable {
    programs.kitty = {
      enable = true;
      font = {
        name = "Comic Code Ligatures";
        size = cfg.fontSize;
      };
      shellIntegration.enableFishIntegration = true;
      theme = "Catppuccin-Mocha";
      settings = {
        "confirm_os_window_close" = "0";
        "tab_bar_min_tabs" = "1";
        "tab_bar_style" = "powerline";
        "tab_powerline_style" = "slanted";
      };
      keybindings = {
        "super+shift+t" = "new_tab";
        "super+shift+w" = "close_tab";
        "super+shift+[" = "previous_tab";
        "super+shift+]" = "next_tab";
      };
    };
  };
}
