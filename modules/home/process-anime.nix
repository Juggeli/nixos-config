{
  flake.homeModules.process-anime =
    { pkgs, ... }:
    {
      home-manager.users.juggeli.home.packages = [ pkgs.process-anime ];
    };
}
