{
  flake.homeModules.nh =
    { pkgs, ... }:
    let
      homeDir = if pkgs.stdenv.isDarwin then "/Users/juggeli" else "/home/juggeli";
    in
    {
      home-manager.users.juggeli = {
        programs.nh = {
          enable = true;
          flake = "${homeDir}/src/dotfiles";
          clean.enable = true;
        };
      };
    };
}
