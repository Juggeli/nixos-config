{
  flake.homeModules.pdf =
    { pkgs, ... }:
    {
      home-manager.users.juggeli = {
        home.packages = [ pkgs.poppler-utils ];

        programs.zathura.enable = true;
        catppuccin.zathura.enable = true;
      };
    };
}
