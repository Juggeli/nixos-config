{
  flake.homeModules.jq =
    { pkgs, ... }:
    {
      home-manager.users.juggeli.home.packages = [ pkgs.jq ];
    };
}
