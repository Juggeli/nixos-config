{ inputs, self, ... }:
{
  flake.lib = {
    mkNixos =
      {
        system,
        hostName,
        modules,
      }:
      inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs self; };
        modules = [
          inputs.home-manager.nixosModules.home-manager
          inputs.agenix.nixosModules.default
          inputs.disko.nixosModules.disko
          inputs.impermanence.nixosModules.impermanence
          inputs.catppuccin.nixosModules.catppuccin
          inputs.neovim.nixosModules.default
          { networking.hostName = hostName; }
        ] ++ modules;
      };

    mkDarwin =
      {
        system,
        hostName,
        modules,
      }:
      inputs.darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit inputs self; };
        modules = [
          inputs.home-manager.darwinModules.home-manager
          inputs.agenix.darwinModules.default
          inputs.catppuccin.darwinModules.catppuccin
          { networking.hostName = hostName; }
        ] ++ modules;
      };
  };
}
