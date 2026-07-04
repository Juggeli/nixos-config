{
  flake.homeModules.lmstudio =
    { pkgs, ... }:
    {
      home-manager.users.juggeli.home.packages = [ pkgs.lmstudio ];

      environment.persistence."/persist-home".users.juggeli.directories = [
        ".lmstudio"
        ".cache/lm-studio"
        ".config/LM Studio"
      ];
    };
}
