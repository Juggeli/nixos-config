{
  options,
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.colors;
in {
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
  };
}
