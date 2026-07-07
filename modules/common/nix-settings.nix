{ ... }:
let
  common =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        git
        nixfmt-tree
        nix-index
        nix-prefetch-git
      ];

      nix = {
        settings = {
          experimental-features = "nix-command flakes";
          http-connections = 50;
          warn-dirty = false;
          log-lines = 50;
          # root is already in trusted-users via the nixos/nix-darwin core
          # modules, but allowed-users replaces its permissive default ("*"),
          # so root must be listed there explicitly
          trusted-users = [ "juggeli" ];
          allowed-users = [
            "root"
            "juggeli"
          ];
          download-buffer-size = 134217728;
          substituters = [
            "https://cache.numtide.com"
            "https://comfyui.cachix.org"
            "https://nix-community.cachix.org"
          ];
          trusted-public-keys = [
            "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
            "comfyui.cachix.org-1:33mf9VzoIjzVbp0zwj+fT51HG0y31ZTK3nzYZAX0rec="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          ];
        };

        package = pkgs.nixVersions.latest;
      };
    };
in
{
  flake.nixosModules.nix-settings = {
    imports = [ common ];
    nix.settings.sandbox = "relaxed";
  };

  flake.darwinModules.nix-settings = {
    imports = [ common ];
    system.primaryUser = "juggeli";
    nix.settings = {
      sandbox = false;
      extra-nix-path = "nixpkgs=flake:nixpkgs";
      build-users-group = "nixbld";
    };
  };
}
