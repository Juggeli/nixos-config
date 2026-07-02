{
  flake.homeModules.neovim =
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
    };
}
