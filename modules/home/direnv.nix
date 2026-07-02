{
  flake.homeModules.direnv = {
    home-manager.users.juggeli = {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    };
  };
}
