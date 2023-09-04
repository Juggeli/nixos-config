inputs@{ options, config, lib, pkgs, ... }:

with lib;
with lib.internal;
let
  cfg = config.plusultra.cli-apps.tmux;
in
{
  options.plusultra.cli-apps.tmux = with types; {
    enable = mkBoolOpt false "Whether or not to enable tmux.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      tmux
    ];
  };
}

