{
  flake.nixosModules.home-kitty =
    { pkgs, ... }:
    {
      home-manager.users.juggeli = {
        home.packages = [ pkgs.wl-clipboard ];

        xdg.configFile."kitty/clip2path" = {
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
            size = 14;
          };
          shellIntegration.enableFishIntegration = true;
          shellIntegration.mode = "no-sudo";
          settings = {
            "shell" = "${pkgs.fish}/bin/fish";
            "symbol_map" =
              "U+23FB-U+23FE,U+2665,U+26A1,U+2B58,U+E000-U+E00A,U+E0A0-U+E0A3,U+E0B0-U+E0D4,U+E200-U+E2A9,U+E300-U+E3E3,U+E5FA-U+E6AA,U+E700-U+E7C5,U+EA60-U+EBEB,U+F000-U+F2E0,U+F300-U+F32F,U+F400-U+F4A9,U+F500-U+F8FF,U+F0001-U+F1AF0 Symbols Nerd Font";
            "confirm_os_window_close" = "0";
            "hide_window_decorations" = "yes";
            "tab_bar_style" = "hidden";
            "enabled_layouts" = "fat:bias=50;full_size=1;mirrored=false";
            "cursor_trail" = "3";
            "cursor_trail_decay" = "0.1 0.4";
            "allow_remote_control" = "yes";
          };
          keybindings = {
            "super+shift+t" = "no_op";
            "super+shift+w" = "no_op";
            "super+shift+[" = "no_op";
            "super+shift+]" = "no_op";
            "ctrl+shift+t" = "no_op";
            "ctrl+shift+w" = "no_op";
            "ctrl+v" = "launch --type=background --allow-remote-control --keep-focus ~/.config/kitty/clip2path";
          };
        };
        catppuccin.kitty.enable = true;
      };
    };
}
