{
  flake.nixosModules.home-neovim =
    { inputs, pkgs, ... }:
    {
      home-manager.users.juggeli = {
        home.packages = [
          inputs.neovim.packages.${pkgs.system}.nvim
        ];

        home.sessionVariables = {
          EDITOR = "nvim";
        };
      };

      environment.persistence."/persist-home" = {
        users.juggeli.directories = [
          ".local/state/nvim"
          ".local/share/nvim"
          ".cache/nvim"
          ".config/github-copilot"
        ];
      };
    };
}
