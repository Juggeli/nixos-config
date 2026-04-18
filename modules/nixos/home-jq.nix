{
  flake.nixosModules.home-jq =
    { pkgs, ... }:
    {
      home-manager.users.juggeli.home.packages = [ pkgs.jq ];
    };
}
