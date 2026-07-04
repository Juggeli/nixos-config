{
  flake.nixosModules.system-fonts =
    { pkgs, ... }:
    {
      environment.variables.LOG_ICONS = "true";

      environment.systemPackages = [ pkgs.font-manager ];

      fonts = {
        packages = with pkgs; [
          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-cjk-serif
          noto-fonts-color-emoji
          ubuntu-classic
          nerd-fonts.jetbrains-mono
          nerd-fonts.symbols-only
          comic-code
        ];
        fontconfig.defaultFonts.monospace = [ "Ubuntu Mono" ];
      };
    };
}
