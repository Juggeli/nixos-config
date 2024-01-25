{ lib, ... }:
with lib;
with lib.plusultra;
{
  options.plusultra.colors = with types; {
    base00 = mkOpt str "#1e1e2e" "base";
    base01 = mkOpt str "#181825" "mantle";
    base02 = mkOpt str "#313244" "surface0";
    base03 = mkOpt str "#45475a" "surface1";
    base04 = mkOpt str "#585b70" "surface2";
    base05 = mkOpt str "#cdd6f4" "text";
    base06 = mkOpt str "#f5e0dc" "rosewater";
    base07 = mkOpt str "#b4befe" "lavender";
    base08 = mkOpt str "#f38ba8" "red";
    base09 = mkOpt str "#fab387" "peach";
    base0A = mkOpt str "#f9e2af" "yellow";
    base0B = mkOpt str "#a6e3a1" "green";
    base0C = mkOpt str "#94e2d5" "teal";
    base0D = mkOpt str "#89b4fa" "blue";
    base0E = mkOpt str "#cba6f7" "mauve";
    base0F = mkOpt str "#f2cdcd" "flamingo";

    base = mkOpt str "#1e1e2e" "base";
    mantle = mkOpt str "#181825" "mantle";
    surface0 = mkOpt str "#313244" "surface0";
    surface1 = mkOpt str "#45475a" "surface1";
    surface2 = mkOpt str "#585b70" "surface2";
    text = mkOpt str "#cdd6f4" "text";
    rosewater = mkOpt str "#f5e0dc" "rosewater";
    lavender = mkOpt str "#b4befe" "lavender";
    red = mkOpt str "#f38ba8" "red";
    peach = mkOpt str "#fab387" "peach";
    yellow = mkOpt str "#f9e2af" "yellow";
    green = mkOpt str "#a6e3a1" "green";
    teal = mkOpt str "#94e2d5" "teal";
    blue = mkOpt str "#89b4fa" "blue";
    mauve = mkOpt str "#cba6f7" "mauve";
    flamingo = mkOpt str "#f2cdcd" "flamingo";
  };
}
