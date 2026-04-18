{
  flake.nixosModules.home-btop = {
    home-manager.users.juggeli = {
      programs.btop.enable = true;
      catppuccin.btop.enable = true;
    };
  };
}
