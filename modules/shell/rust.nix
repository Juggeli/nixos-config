{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let
  cfg = config.modules.shell.rust;
  configDir = config.dotfiles.configDir;
in
{
  options.modules.shell.rust = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      cargo
      rust-analyzer
      rustc
    ];

    hm.home.sessionPath = [ "$HOME/.cargo/bin" ];
  };
}
