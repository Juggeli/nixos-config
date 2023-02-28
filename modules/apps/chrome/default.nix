{ options, config, lib, pkgs, inputs, ... }:

with lib;
with lib.internal;
let
  cfg = config.plusultra.apps.chrome;
in
{
  options.plusultra.apps.chrome = with types; {
    enable = mkBoolOpt false "Whether or not to enable Chrome.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      (google-chrome.override {
       commandLineArgs = [
       "--enable-features=WebUIDarkMode"
       "--force-dark-mode"
       ];
       })
    ];
  };
}