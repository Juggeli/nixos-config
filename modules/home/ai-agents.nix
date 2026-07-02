{
  flake.homeModules.ai-agents =
    { inputs, pkgs, ... }:
    let
      llm-agents = inputs.llm-agents.packages.${pkgs.system};
    in
    {
      home-manager.users.juggeli.home.packages = [
        llm-agents.codex
        llm-agents.agent-browser
        pkgs.uv
      ];
    };
}
