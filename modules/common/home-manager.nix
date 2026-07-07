{ inputs, ... }:
let
  mkHomeManager = homeDirectory: {
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
        home.homeDirectory = homeDirectory;
        xdg.enable = true;
        catppuccin = {
          enable = true;
          flavor = "mocha";
          accent = "flamingo";
        };
      };
    };
  };
in
{
  flake.nixosModules.home-manager = mkHomeManager "/home/juggeli";
  flake.darwinModules.home-manager = mkHomeManager "/Users/juggeli";
}
