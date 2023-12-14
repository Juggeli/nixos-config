{ lib, pkgs, config, ... }:

with lib;
with lib.plusultra;
let
  cfg = config.plusultra.desktop.addons.spacebar;
in
{
  options.plusultra.desktop.addons.spacebar = {
    enable = mkEnableOption "Spacebar";
  };

  config = mkIf cfg.enable {
    services.spacebar = {
      enable = true;
      package = pkgs.spacebar;

      config = {
        position = "top";
        display = "all";
        height = 32;
        title = "off";
        spaces = "on";
        clock = "on";
        power = "on";

        padding_left = 10;
        padding_right = 15;

        spacing_left = 10;
        spacing_right = 15;

        foreground_color = "0xffeceff4";
        background_color = "0xff1d2128";

        text_font = ''"Hack Nerd Font Mono:Regular:14.0"'';
        icon_font = ''"Hack Nerd Font Mono:Regular:20.0"'';

        clock_icon = "";

        # Shell entries apparently break the whole bar...
        # https://github.com/cmacrae/spacebar/issues/104
        # right_shell_icon = "";
        # right_shell_command = ''"whoami"'';
        # right_shell = "on";
      };
    };
  };
}