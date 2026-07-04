{ inputs, ... }:
{
  flake.darwinModules.home-manager = {
    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
      backupFileExtension = "hm-backup";
      extraSpecialArgs = { inherit inputs; };
      sharedModules = [
        inputs.catppuccin.homeModules.catppuccin
      ];
      users.juggeli = {
        home.stateVersion = "23.11";
        home.username = "juggeli";
        home.homeDirectory = "/Users/juggeli";
        xdg.enable = true;
        catppuccin = {
          enable = true;
          flavor = "mocha";
          accent = "flamingo";
        };
      };
    };
  };
}
