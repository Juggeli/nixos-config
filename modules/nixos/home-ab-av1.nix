{
  flake.nixosModules.home-ab-av1 =
    { pkgs, ... }:
    {
      home-manager.users.juggeli.home.packages = [ pkgs.ab-av1 ];
    };
}
