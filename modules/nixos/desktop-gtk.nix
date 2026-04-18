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
      };
    };
}
