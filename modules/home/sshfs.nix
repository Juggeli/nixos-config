{
  flake.homeModules.sshfs =
    { pkgs, ... }:
    {
      home-manager.users.juggeli.home.packages = [ pkgs.sshfs ];
    };
}
