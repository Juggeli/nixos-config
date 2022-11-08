{ config, options, pkgs, lib, ... }:

with lib;
with lib.my;
let
  cfg = config.modules.shell.util;
in
{
  options.modules.shell.util = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm.programs.fzf = {
      enable = true;
      enableZshIntegration = hm.programs.zsh.enable;
      historyWidgetOptions = [ "--reverse" ];
    };

    hm.home.packages = with pkgs; [
      bat
      exa
      fd
      tldr
      pciutils
      grc
    ];
  };
}

