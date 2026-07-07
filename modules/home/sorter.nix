{
  flake.homeModules.sorter =
    { pkgs, ... }:
    {
      home-manager.users.juggeli.home.packages = [ pkgs.sorter ];
    };
}
