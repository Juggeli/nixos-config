{
  flake.darwinModules.fonts =
    { pkgs, ... }:
    {
      environment.variables = {
        LOG_ICONS = "true";
      };

      fonts.packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
        nerd-fonts.hack
        nerd-fonts.jetbrains-mono
        nerd-fonts.symbols-only
        nerd-fonts.fantasque-sans-mono
        comic-code
      ];
    };
}
