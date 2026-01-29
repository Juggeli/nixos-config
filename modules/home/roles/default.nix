{
  config,
  lib,
  inputs,
  ...
}:

with lib;
with lib.plusultra;
let
  cfg = config.plusultra.roles.home-common;
in
{
  options.plusultra.roles.home-common = with types; {
    enable = mkBoolOpt false "Whether to enable common home configuration";
  };

  imports = [ (inputs.catppuccin.homeModules.catppuccin) ];

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
        wezterm = enabled;
        ghostty = enabled;
        mpv = enabled;
      };
      cli-apps = {
        fish = enabled;
        nh = enabled;
        neovim = enabled;
        btop = enabled;
        lazygit = enabled;
        jq = enabled;
        yazi = enabled;
        bat = enabled;
        ai-agents = enabled;
        opencode = enabled;
        claude-code = enabled;
        tmux = enabled;
        cw = enabled;
      };
      tools = {
        git = enabled;
        direnv = enabled;
        devtools = enabled;
        hdd-scraper = enabled;
      };
    };
    catppuccin = {
      flavor = "mocha";
      accent = "flamingo";
    };
  };
}
