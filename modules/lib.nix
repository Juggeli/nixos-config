{ inputs, self, ... }:
let
  mkBaseModule = hostName: {
    networking.hostName = hostName;
    nixpkgs.config.allowUnfree = true;
    nixpkgs.overlays = self.lib.overlays;
  };
in
{
  flake.lib = {
    overlays = [
      inputs.nur.overlays.default
      self.overlays.default
    ];

    mkNixos =
      {
        hostName,
        modules,
        system ? "x86_64-linux",
      }:
      inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs self; };
        modules = [
          (mkBaseModule hostName)
          inputs.home-manager.nixosModules.home-manager
          inputs.agenix.nixosModules.default
          inputs.disko.nixosModules.disko
          inputs.impermanence.nixosModules.impermanence
          inputs.catppuccin.nixosModules.catppuccin
          inputs.neovim.nixosModules.default
        ]
        ++ modules;
      };

    mkDarwin =
      {
        hostName,
        modules,
        system ? "aarch64-darwin",
      }:
      inputs.darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit inputs self; };
        modules = [
          (mkBaseModule hostName)
          inputs.home-manager.darwinModules.home-manager
          inputs.agenix.darwinModules.default
        ]
        ++ modules;
      };
  };
}
