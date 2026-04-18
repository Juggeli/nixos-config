{
  flake.nixosModules.desktop-qt = {
    home-manager.users.juggeli.qt = {
      enable = true;
      platformTheme.name = "adwaita";
      style.name = "adwaita-dark";
    };
  };
}
