{
  flake.nixosModules.desktop-gtk =
    { pkgs, ... }:
    {
      home-manager.users.juggeli = {
        dconf.settings = {
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
          };
        };
        gtk = {
          enable = true;
          theme = {
            name = "Adwaita-dark";
            package = pkgs.gnome-themes-extra;
          };
        };
        home.pointerCursor = {
          x11.enable = true;
          gtk.enable = true;
          package = pkgs.banana-cursor-dreams;
          size = 64;
          name = "Banana-Catppuccin-Mocha";
        };
      };
    };
}
