{
  flake.nixosModules.home-hydrus =
    { pkgs, ... }:
    {
      home-manager.users.juggeli = {
        home.packages = [ pkgs.hydrus ];

        xdg.desktopEntries.hydrus-client = {
          name = "Hydrus Client";
          exec = "${pkgs.hydrus}/bin/hydrus-client -d /hydrus";
          icon = "hydrus-client";
          comment = "Hydrus Client - A personal booru application";
        };
      };
    };
}
