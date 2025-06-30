{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.apps.ghostty;

  # Apply our overlay to unstable packages
  unstableWithOverlay = inputs.unstable.legacyPackages.${pkgs.system}.extend (
    final: prev: {
      ghostty-bin = prev.ghostty-bin.overrideAttrs (oldAttrs: rec {
        version = "tip-2025-06-28";

        src = prev.fetchurl {
          url = "https://github.com/ghostty-org/ghostty/releases/download/tip/Ghostty.dmg";
          hash = "sha256-dInGK34IEp1wLXUbVA3xXOsPxLCBbMgrncmBggriRhs=";
        };

        meta = oldAttrs.meta // {
          description = "Ghostty terminal emulator (nightly build)";
          longDescription = ''
            Fast, feature-rich, and cross-platform terminal emulator that uses 
            platform-native UI and GPU acceleration. This is a nightly build 
            from the tip of the main branch.
          '';
        };
      });
    }
  );

  ghosttyPackage = if pkgs.stdenv.isDarwin then unstableWithOverlay.ghostty-bin else pkgs.ghostty;
in
{
  options.plusultra.apps.ghostty = with types; {
    enable = mkBoolOpt false "Whether or not to enable ghostty.";
    fontSize = mkOpt types.int 14 "Font size to use with ghostty.";
    shader = mkOpt (types.enum [
      "none"
      "cursor_blaze"
      "cursor_blaze_no_trail"
      "cursor_smear"
      "cursor_smear_fade"
    ]) "cursor_smear" "Cursor shader to use.";
  };

  config = mkIf cfg.enable {
    home.packages = [
      ghosttyPackage
    ];

    xdg.configFile."ghostty/config" = {
      text = ''
        font-family = Comic Code Ligatures
        font-size = ${toString cfg.fontSize}

        command = ${pkgs.fish}/bin/fish

        window-decoration = false
        window-padding-x = 4
        window-padding-y = 4

        confirm-close-surface = false

        theme = catppuccin-mocha

        # cursor-style-blink = false
        ${optionalString (cfg.shader != "none") "custom-shader = shaders/${cfg.shader}.glsl"}
      '';
    };

    xdg.configFile."ghostty/shaders/cursor_blaze.glsl".source = ./shaders/cursor_blaze.glsl;
    xdg.configFile."ghostty/shaders/cursor_blaze_no_trail.glsl".source =
      ./shaders/cursor_blaze_no_trail.glsl;
    xdg.configFile."ghostty/shaders/cursor_smear.glsl".source = ./shaders/cursor_smear.glsl;
    xdg.configFile."ghostty/shaders/cursor_smear_fade.glsl".source = ./shaders/cursor_smear_fade.glsl;
  };
}
