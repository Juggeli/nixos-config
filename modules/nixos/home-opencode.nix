{
  flake.nixosModules.home-opencode =
    { inputs, pkgs, ... }:
    let
      llm-agents = inputs.llm-agents.packages.${pkgs.system};
    in
    {
      home-manager.users.juggeli.home.packages = [
        llm-agents.opencode
      ];

      environment.persistence."/persist-home" = {
        users.juggeli.directories = [
          ".cache/opencode"
          ".config/opencode"
          ".local/share/opencode"
          ".local/state/opencode"
        ];
      };
    };
}
