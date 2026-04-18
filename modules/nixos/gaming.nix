{
  flake.nixosModules.gaming =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.heroic ];
      programs.steam.enable = true;

      environment.persistence."/persist-home" = {
        users.juggeli.directories = [
          ".local/share/Steam"
          ".steam"
          ".config/heroic"
        ];
      };
    };
}
