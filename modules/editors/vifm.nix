{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let
  cfg = config.modules.editors.vifm;
  configDir = config.dotfiles.configDir;
in
{
  options.modules.editors.vifm = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      (vifm.overrideAttrs (attrs: {
        patches = [ ./vifm.patch ];
      }))
    ];

    hm.xdg.configFile."vifm/vifmrc".source = "${configDir}/vifmrc";
  };
}

