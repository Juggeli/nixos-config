{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.tools.rust;
in
{
  options.plusultra.tools.rust = with types; {
    enable = mkBoolOpt false "Whether or not to install and configure rust env.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      rustup
      clang
      pkg-config
    ];

    plusultra.home.extraOptions = {
      home.sessionPath = [ "$HOME/.cargo/bin" ];
    };
  };
}
