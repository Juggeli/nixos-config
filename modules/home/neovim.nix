{
  flake.homeModules.neovim =
    { inputs, pkgs, ... }:
    {
      home-manager.users.juggeli = {
        home.packages = [
          inputs.neovim.packages.${pkgs.stdenv.hostPlatform.system}.nvim
        ];

        home.sessionVariables = {
          EDITOR = "nvim";
        };
      };
    };
}
