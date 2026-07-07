{
  flake.homeModules.discord =
    { pkgs, ... }:
    {
      home-manager.users.juggeli = {
        home.packages = [ pkgs.discord ];

        xdg.configFile."discord/settings.json".source = ./_assets/settings.json;
      };
    };
}
