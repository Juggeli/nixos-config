{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.cli-apps.opencode;
  llm-agents = inputs.llm-agents.packages.${pkgs.system};
in
{
  options.plusultra.cli-apps.opencode = with types; {
    enable = mkBoolOpt false "Whether or not to enable opencode.";
  };

  config = mkIf cfg.enable {
    home.packages = [
      llm-agents.opencode
    ];

    plusultra.user.impermanence = {
      directories = [
        ".cache/opencode"
        ".config/opencode"
        ".local/share/opencode"
        ".local/state/opencode"
      ];
    };
  };
}
