{
  description = "Juggeli's NixOS system";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    snowfall-lib = {
      url = "github:snowfallorg/lib/dev";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:nixos/nixos-hardware";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "unstable";
    };

    # Discord Replugged
    replugged = {
      url = "github:LunNova/replugged-nix-flake";
      inputs.nixpkgs.follows = "unstable";
    };

    # Discord Replugged plugins / themes
    discord-tweaks = {
      url = "github:NurMarvin/discord-tweaks";
      flake = false;
    };

    neovim = {
      url = "github:Juggeli/neovim";
      inputs.nixpkgs.follows = "unstable";
    };

    # hyprland = {
    #   url = "github:hyprwm/Hyprland";
    #   inputs.nixpkgs.follows = "unstable";
    # };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "unstable";
    };
  };

  outputs = inputs:
    let
      lib = inputs.snowfall-lib.mkLib {
        inherit inputs;
        src = ./.;

        snowfall = {
          meta = {
            name = "plusultra";
            title = "Plus Ultra";
          };

          namespace = "plusultra";
        };
      };
    in
    lib.mkFlake {      
      channels-config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "electron-25.9.0"
        ];
      };

      overlays = with inputs; [
        neovim.overlays.default
      ];

      systems.modules.nixos = with inputs; [
        home-manager.nixosModules.home-manager
        # hyprland.nixosModules.default
        agenix.nixosModules.default
      ];

      deploy = lib.mkDeploy {inherit (inputs) self;};

      checks =
        builtins.mapAttrs
        (system: deploy-lib:
          deploy-lib.deployChecks inputs.self.deploy)
        inputs.deploy-rs.lib;
    };
}
