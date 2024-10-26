{ config, lib, ... }:
with lib;
with lib.plusultra;
let
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
      shellIntegration.mode = "no-sudo";
      catppuccin.enable = true;
      settings = {
        "shell" = "/run/current-system/sw/bin/fish";
        "symbol_map" = "U+23FB-U+23FE,U+2665,U+26A1,U+2B58,U+E000-U+E00A,U+E0A0-U+E0A3,U+E0B0-U+E0D4,U+E200-U+E2A9,U+E300-U+E3E3,U+E5FA-U+E6AA,U+E700-U+E7C5,U+EA60-U+EBEB,U+F000-U+F2E0,U+F300-U+F32F,U+F400-U+F4A9,U+F500-U+F8FF,U+F0001-U+F1AF0 Symbols Nerd Font";
        "confirm_os_window_close" = "0";
        "tab_bar_min_tabs" = "1";
        "tab_bar_style" = "powerline";
        "tab_powerline_style" = "slanted";
        "hide_window_decorations" = "yes";
        "tab_title_max_length" = "60";
        "tab_title_template" = "{fmt.fg.tab}{index}: {tab.active_oldest_exe}";
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
