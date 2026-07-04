{
  flake.homeModules.opencode =
    { inputs, pkgs, ... }:
    let
      llm-agents = inputs.llm-agents.packages.${pkgs.system};
    in
    {
      home-manager.users.juggeli.home.packages = [
        llm-agents.opencode
      ];
    };
}
