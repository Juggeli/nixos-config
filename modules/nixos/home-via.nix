{
  flake.nixosModules.home-via =
    { pkgs, ... }:
    {
      home-manager.users.juggeli.home.packages = [ pkgs.via ];
    };
}
