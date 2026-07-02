{
  flake.homeModules.ghostty =
    { pkgs, ... }:
    let
      ghosttyPackage = if pkgs.stdenv.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
    in
    {
      home-manager.users.juggeli =
        { lib, config, ... }:
        {
          options.ghostty.fontSize = lib.mkOption {
            type = lib.types.int;
            default = 14;
            description = "Font size to use with ghostty.";
          };

          config = {
            home.packages = [ ghosttyPackage ];

            xdg.configFile."ghostty/config".text = ''
              font-family = Comic Code Ligatures
              font-size = ${toString config.ghostty.fontSize}

              command = ${pkgs.fish}/bin/fish

              window-decoration = false
              window-padding-x = 4
              window-padding-y = 4

              confirm-close-surface = false

              theme = Catppuccin Mocha
            '';
          };
        };
    };
}
