{
  flake.nixosModules.home-hdd-scraper =
    { pkgs, ... }:
    {
      home-manager.users.juggeli.home.packages = [ pkgs.hdd-scraper ];
    };
}
