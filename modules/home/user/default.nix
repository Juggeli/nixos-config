{
  lib,
  config,
  pkgs,
  ...
}:

with lib;
with lib.plusultra;
let
  cfg = config.plusultra.user;
  is-darwin = pkgs.stdenv.isDarwin;
  home-directory =
    if cfg.name == null then
      null
    else if is-darwin then
      "/Users/${cfg.name}"
    else
      "/home/${cfg.name}";
in
{
  imports = [
    ./impermanence.nix
  ];
  options.plusultra.user = {
    enable = mkOpt types.bool false "Whether to configure the user account.";
    name = mkOpt (types.nullOr types.str) config.snowfallorg.user.name "The user account.";

    fullName = mkOpt types.str "Jukka Alavesa" "The full name of the user.";
    email = mkOpt types.str "juggeli@gmail.com" "The email of the user.";

    home = mkOpt (types.nullOr types.str) home-directory "The user's home directory.";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = cfg.name != null;
          message = "plusultra.user.name must be set";
        }
        {
          assertion = cfg.home != null;
          message = "plusultra.user.home must be set";
        }
      ];

      home = {
        username = mkDefault cfg.name;
        homeDirectory = mkDefault cfg.home;
      };
    }
  ]);
}
