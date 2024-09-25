{ config, lib, ... }:

with lib;
with lib.plusultra;
let
  cfg = config.plusultra.roles.home-common;
in
{
  options.plusultra.roles.home-common = with types; {
    enable = mkBoolOpt false "Whether to enable common home configuration";
  };

  config = mkIf cfg.enable {
    plusultra = {
      user = {
        enable = true;
        name = config.snowfallorg.user.name;
      };
      apps = {
        kitty = {
          enable = true;
          fontSize = 15;
        };
        mpv = enabled;
      };
      cli-apps = {
        fish = enabled;
        neovim = enabled;
        btop = enabled;
        lazygit = enabled;
        jq = enabled;
      };
      tools = {
        git = enabled;
        direnv = enabled;
      };
    };
  };
}
