{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
with lib.plusultra;
let
  cfg = config.plusultra.system.fonts;
in
{
  options.plusultra.system.fonts = with types; {
    enable = mkBoolOpt false "Whether or not to manage fonts.";
    fonts = mkOpt (listOf package) [ ] "Custom font packages to install.";
  };

  config = mkIf cfg.enable {
    environment.variables = {
      # Enable icons in tooling since we have nerdfonts.
      LOG_ICONS = "true";
    };

    fonts = {
      packages =
        with pkgs;
        [
          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-cjk-serif
          noto-fonts-emoji
          nerd-fonts.hack
          nerd-fonts.jetbrains-mono
          nerd-fonts.symbols-only
          nerd-fonts.fantasque-sans-mono
          plusultra.comic-code
        ]
        ++ cfg.fonts;
    };
  };
}
