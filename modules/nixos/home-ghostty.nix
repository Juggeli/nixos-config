{
  flake.nixosModules.home-ghostty =
    { pkgs, ... }:
    {
      home-manager.users.juggeli = {
        home.packages = [ pkgs.ghostty ];

        xdg.configFile."ghostty/config".text = ''
          font-family = Comic Code Ligatures
          font-size = 14

          command = ${pkgs.fish}/bin/fish

          window-decoration = false
          window-padding-x = 4
          window-padding-y = 4

          confirm-close-surface = false

          theme = Catppuccin Mocha
        '';
      };
    };
}
