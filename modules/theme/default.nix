{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.theme;
in {
  options.modules.theme = with types; {
    enable = mkBoolOpt false;

    colors = {
      black         = mkOpt str "#282c34";
      red           = mkOpt str "#ff6c6b";
      green         = mkOpt str "#98be65";
      yellow        = mkOpt str "#ECBE7B";
      blue          = mkOpt str "#2257A0";
      magenta       = mkOpt str "#c678dd";
      cyan          = mkOpt str "#5699AF";
      silver        = mkOpt str "#e2e2dc";
      grey          = mkOpt str "#5B6268";
      brightred     = mkOpt str "#de935f";
      brightgreen   = mkOpt str "#0189cc";
      brightyellow  = mkOpt str "#f9a03f";
      brightblue    = mkOpt str "#51afef";
      brightmagenta = mkOpt str "#ff79c6";
      brightcyan    = mkOpt str "#0189cc";
      white         = mkOpt str "#bbc2cf";

      base0         = mkOpt str "#1B2229";
      base1         = mkOpt str "#1c1f24";
      base2         = mkOpt str "#202328";
      base3         = mkOpt str "#23272e";
      base4         = mkOpt str "#3f444a";
      base5         = mkOpt str "#5B6268";
      base6         = mkOpt str "#73797e";
      base7         = mkOpt str "#9ca0a4";
      base8         = mkOpt str "#DFDFDF";
    };

    fonts = {
      mono = {
        name = mkOpt str "ComicCodeLigatures Nerd Font";
        size = mkOpt int 12;
      };
      sans = {
        name = mkOpt str "Fira Sans";
        size = mkOpt int 10;
      };
    };

    gtk = {
      theme = {
        name = mkOpt str "Dracula";
        package = mkOpt package pkgs.dracula-theme;
      };
      iconTheme = {
        name = mkOpt str "Arc";
        package = mkOpt package pkgs.arc-icon-theme;
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.gtk = {
        enable = true;
        font = {
          name = cfg.fonts.sans.name;
        };
        theme = {
          name = cfg.gtk.theme.name;
          package = cfg.gtk.theme.package;
        };
        iconTheme = {
          name = cfg.gtk.iconTheme.name;
          package = cfg.gtk.iconTheme.package;
        };
        gtk3.extraConfig = {
          gtk-application-prefer-dark-theme = true;
          gtk-icon-theme-name = cfg.gtk.iconTheme.name;
        };
      };

      # home.systemDirs.data = [
      #   "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
      #   "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
      # ];

      fonts.fonts = with pkgs; [
        fira-code
        fira-code-symbols
        open-sans
        jetbrains-mono
        siji
        font-awesome
        my.comic-code
      ];

      fonts.fontconfig.defaultFonts = {
        sansSerif = [ cfg.fonts.sans.name ];
        monospace = [ cfg.fonts.mono.name ];
      };

      # Other dotfiles
      xdg.configFile = with config.modules; mkMerge [
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
