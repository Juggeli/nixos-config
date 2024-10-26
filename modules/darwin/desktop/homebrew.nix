{ lib, config, ... }:

with lib;
with lib.plusultra;
let
  cfg = config.plusultra.desktop.homebrew;
in
{
  options.plusultra.desktop.homebrew = {
    enable = mkBoolOpt false "Whether to enable homebrew";
  };

  config = mkIf cfg.enable {
    homebrew = {
      enable = true;
      brews = [ "lutzifer/homebrew-tap/keyboardSwitcher" ];
      taps = [ "lutzifer/tap" ];
      casks = [
        "obsidian"
        "zen-browser"
      ];
    };
  };
}
