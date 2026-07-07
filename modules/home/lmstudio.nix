{
  flake.homeModules.lmstudio =
    { pkgs, ... }:
    {
      home-manager.users.juggeli.home.packages = [ pkgs.lmstudio ];
    };
}
