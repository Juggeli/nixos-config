{
  flake.homeModules.anytype =
    { pkgs, ... }:
    {
      home-manager.users.juggeli.home.packages = [ pkgs.anytype ];

      environment.persistence."/persist-home" = {
        users.juggeli.directories = [
          ".config/anytype"
        ];
      };
    };
}
