{
  flake.nixosModules.home-nh = {
    home-manager.users.juggeli = {
      programs.nh = {
        enable = true;
        flake = "/home/juggeli/src/dotfiles";
        clean.enable = true;
      };
    };
  };
}
