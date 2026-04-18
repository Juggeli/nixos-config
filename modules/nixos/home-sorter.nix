{
  flake.nixosModules.home-sorter =
    { pkgs, ... }:
    {
      home-manager.users.juggeli.home.packages = [ pkgs.sorter ];

      environment.persistence."/persist-home" = {
        users.juggeli.directories = [
          ".config/sorter"
        ];
      };
    };
}
