{
  flake.nixosModules.desktop-qt =
    { lib, ... }:
    {
      home-manager.users.juggeli = {
        qt = {
          enable = true;
          platformTheme.name = "adwaita";
          style.name = "adwaita-dark";
        };
        catppuccin.kvantum.enable = lib.mkForce false;
      };
    };
}
