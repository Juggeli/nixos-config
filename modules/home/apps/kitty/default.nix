{
  config,
  lib,
  pkgs,
  ...
}:
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
    home.packages = with pkgs; mkIf pkgs.stdenv.isLinux [ wl-clipboard ];

    # Workaround for pasting images to Claude Code
    xdg.configFile."kitty/clip2path" = mkIf pkgs.stdenv.isLinux {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -e

        types=$(wl-paste --list-types)

        if grep -q '^text/' <<<"$types"; then
            wl-paste --no-newline | kitty @ send-text --stdin             
        elif grep -q '^image/' <<<"$types"; then
            ext=$(grep -m1 '^image/' <<<"$types" | cut -d/ -f2 | cut -d';' -f1)
            file="/tmp/clip_$(date +%s).''${ext}"
            wl-paste > "$file"
            printf '%q' "$file" | kitty @ send-text --stdin             
        else
            wl-paste --no-newline | kitty @ send-text --stdin
        fi
      '';
    };

    programs.kitty = {
      enable = true;
      font = {
        name = "Comic Code Ligatures";
        size = cfg.fontSize;
      };
      shellIntegration.enableFishIntegration = true;
      shellIntegration.mode = "no-sudo";
      settings =
        {
          "shell" = "tmux new-session -A -s kitty-$$";
          "symbol_map" =
            "U+23FB-U+23FE,U+2665,U+26A1,U+2B58,U+E000-U+E00A,U+E0A0-U+E0A3,U+E0B0-U+E0D4,U+E200-U+E2A9,U+E300-U+E3E3,U+E5FA-U+E6AA,U+E700-U+E7C5,U+EA60-U+EBEB,U+F000-U+F2E0,U+F300-U+F32F,U+F400-U+F4A9,U+F500-U+F8FF,U+F0001-U+F1AF0 Symbols Nerd Font";
          "confirm_os_window_close" = "0";
          "hide_window_decorations" = "yes";
          "tab_bar_style" = "hidden";
          "enabled_layouts" = "fat:bias=50;full_size=1;mirrored=false";
          "cursor_trail" = "3";
          "cursor_trail_decay" = "0.1 0.4";
        }
        // (optionalAttrs pkgs.stdenv.isLinux {
          "allow_remote_control" = "yes";
        });
      keybindings =
        {
          "super+shift+t" = "no_op";
          "super+shift+w" = "no_op";
          "super+shift+[" = "no_op";
          "super+shift+]" = "no_op";
          "ctrl+shift+t" = "no_op";
          "ctrl+shift+w" = "no_op";
        }
        // (optionalAttrs pkgs.stdenv.isLinux {
          "ctrl+v" = "launch --type=background --allow-remote-control --keep-focus ~/.config/kitty/clip2path";
        });
    };
    catppuccin.kitty.enable = true;
  };
}
