{
  flake.homeModules.anytype =
    { pkgs, ... }:
    {
      home-manager.users.juggeli.home.packages = [ pkgs.anytype ];
    };
}
