{ inputs, ... }:
{
  flake.nixosModules.home-manager = {
    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
      backupFileExtension = "hm-backup";
      extraSpecialArgs = { inherit inputs; };
      users.juggeli = {
        home.stateVersion = "23.11";
        home.username = "juggeli";
        home.homeDirectory = "/home/juggeli";
        xdg.enable = true;
      };
    };
  };
}
