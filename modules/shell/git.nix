{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let 
  cfg = config.modules.shell.git;
  configDir = config.dotfiles.configDir;
in {
  options.modules.shell.git = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      git
    ];

    xdg.configFile = {
      "git/config".source = "${configDir}/git/config";
      "git/ignore".source = "${configDir}/git/ignore";
    };
  };
}
