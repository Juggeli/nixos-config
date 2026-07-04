{
  flake.homeModules.rclone =
    { pkgs, ... }:
    {
      home-manager.users.juggeli.home.packages = [ pkgs.rclone ];
    };
}
