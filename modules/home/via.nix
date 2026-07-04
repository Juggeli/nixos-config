{
  flake.homeModules.via =
    { pkgs, ... }:
    {
      home-manager.users.juggeli.home.packages = [ pkgs.via ];
    };
}
