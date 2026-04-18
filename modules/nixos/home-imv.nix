{
  flake.nixosModules.home-imv = {
    home-manager.users.juggeli = {
      programs.imv.enable = true;
      catppuccin.imv.enable = true;
    };
  };
}
