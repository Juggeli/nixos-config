{
  flake.nixosModules.home-rclone =
    { pkgs, ... }:
    {
      home-manager.users.juggeli.home.packages = [ pkgs.rclone ];
    };
}
