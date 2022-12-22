{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.browsers.chrome;
in {
  options.modules.desktop.browsers.chrome = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable (mkMerge [
    {
      user.packages = with pkgs; [
        (google-chrome.override {
          commandLineArgs = [
            "--enable-features=WebUIDarkMode"
            "--force-dark-mode"
          ];
        })
      ];
    }
  ]);
}
