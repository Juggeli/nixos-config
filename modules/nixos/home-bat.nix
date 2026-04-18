{
  flake.nixosModules.home-bat = {
    home-manager.users.juggeli = {
      programs.bat.enable = true;
      catppuccin.bat.enable = true;
    };

    environment.persistence."/persist-home" = {
      users.juggeli.directories = [
        ".cache/bat"
      ];
    };
  };
}
