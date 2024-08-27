{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.apps.chrome;
in
{
  options.plusultra.apps.chrome = with types; {
    enable = mkBoolOpt false "Whether or not to enable Chrome.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      (google-chrome.override {
        commandLineArgs = [
          "--enable-features=WebUIDarkMode"
          "--force-dark-mode"
        ];
      })
    ];
  };
}
