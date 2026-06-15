{
  flake.nixosModules.gaming =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.heroic ];
      programs.steam.enable = true;

      # heroic depends on electron_39, which is EOL but has no newer alternative yet
      nixpkgs.config.permittedInsecurePackages = [ "electron-39.8.10" ];

      environment.persistence."/persist-home" = {
        users.juggeli.directories = [
          ".local/share/Steam"
          ".steam"
          ".config/heroic"
        ];
      };
    };
}
