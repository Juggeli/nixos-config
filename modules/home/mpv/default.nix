{
  flake.homeModules.mpv =
    { pkgs, ... }:
    {
      home-manager.users.juggeli = {
        home.packages = with pkgs; [
          (mpv.override {
            scripts = [ ];
            youtubeSupport = false;
          })
        ];

        xdg.configFile = {
          "mpv/mpv.conf".text = ''
            volume=40
            osd-on-seek=msg
            autofit=1920x1080
            deband=no
          '';
          "mpv/input.conf".text = ''
            WHEEL_DOWN seek -10
            WHEEL_UP seek 10
            WHEEL_RIGHT add volume 2
            WHEEL_LEFT add volume -2
            i script-binding show-position-info
          '';
          "mpv/scripts/delete_file.lua".source = ./_assets/delete_file.lua;
          "mpv/scripts/position_info.lua".source = ./_assets/position_info.lua;
          "mpv/scripts/brightness_control.lua".source = ./_assets/brightness_control.lua;
        };
      };
    };
}
