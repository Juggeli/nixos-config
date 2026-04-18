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
    enable = mkBoolOpt false "Whether or not to enable ungoogled-chromium.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      (ungoogled-chromium.override {
        commandLineArgs = [
          "--enable-features=WebUIDarkMode"
          "--force-dark-mode"
        ];
      })
    ];

    plusultra.user.impermanence.directories = [
      ".config/chromium"
      ".cache/chromium"
    ];
  };
}
