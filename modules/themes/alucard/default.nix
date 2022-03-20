# modules/themes/alucard/default.nix --- a regal dracula-inspired theme

{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.theme;
in {
  config = mkIf (cfg.active == "alucard") (mkMerge [
    # Desktop-agnostic configuration
    {
      modules = {
        theme = {
          wallpaper = mkDefault ./config/wallpaper.png;
          gtk = {
            theme = "Dracula";
            iconTheme = "Paper";
            cursorTheme = "Paper";
          };
          fonts = {
            sans.name = "Fira Sans";
            mono.name = "Fira Code";
          };
          colors = {
            black         = "#282c34";
            red           = "#ff6c6b";
            green         = "#98be65";
            yellow        = "#ECBE7B";
            blue          = "#2257A0";
            magenta       = "#c678dd";
            cyan          = "#5699AF";
            silver        = "#e2e2dc";
            grey          = "#5B6268";
            brightred     = "#de935f";
            brightgreen   = "#0189cc";
            brightyellow  = "#f9a03f";
            brightblue    = "#51afef";
            brightmagenta = "#ff79c6";
            brightcyan    = "#0189cc";
            white         = "#bbc2cf";

            base0         = "#1B2229";
            base1         = "#1c1f24";
            base2         = "#202328";
            base3         = "#23272e";
            base4         = "#3f444a";
            base5         = "#5B6268";
            base6         = "#73797e";
            base7         = "#9ca0a4";
            base8         = "#DFDFDF";
          };
        };

        shell.zsh.rcFiles  = [ ./config/zsh/prompt.zsh ];
        desktop.browsers = {
          firefox.userChrome = concatMapStringsSep "\n" readFile [
            ./config/firefox/userChrome.css
          ];
        };
      };
      user.packages = with pkgs; [
        dracula-theme
        paper-icon-theme # for rofi
      ];
      fonts = {
        fonts = with pkgs; [
          fira-code
          fira-code-symbols
          open-sans
          jetbrains-mono
          siji
          font-awesome
        ];
      };

      # Other dotfiles
      home.configFile = with config.modules; mkMerge [
        {
          # Sourced from sessionCommands in modules/themes/default.nix
          "xtheme/90-theme".source = ./config/Xresources;
        }
        (mkIf desktop.apps.rofi.enable {
          "rofi/theme" = { source = ./config/rofi; recursive = true; };
        })
        (mkIf desktop.sway.enable {
          "waybar/style.css".text = import ./config/waybar/style.css cfg;
          "sway/sway.theme".text = import ./config/sway.theme cfg;
        })
      ];
    }
  ]);
}
