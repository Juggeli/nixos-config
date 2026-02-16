{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.plusultra;
let
  cfg = config.plusultra.tools.devtools;
in
{
  options.plusultra.tools.devtools = with types; {
    enable = mkBoolOpt false "Whether or not to enable development tools.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      nodejs
      typescript
      bun
      python3
      pipx
      uv
      husky
      typescript-go
    ];
  };
}
