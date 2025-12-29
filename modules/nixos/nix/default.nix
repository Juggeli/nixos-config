{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.nix;
  users = [
    "root"
    config.plusultra.user.name
  ];
in
{
  options.plusultra.nix = with types; {
    enable = mkBoolOpt true "Whether or not to manage nix configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      git
      deploy-rs
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
        sandbox = "relaxed";
        trusted-users = users;
        allowed-users = users;
        download-buffer-size = 134217728;
        substituters = [ "https://claude-code.cachix.org" ];
        trusted-public-keys = [ "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk=" ];
      };

      package = pkgs.nixVersions.latest;

      # flake-utils-plus
      generateRegistryFromInputs = true;
      generateNixPathFromInputs = true;
      linkInputs = true;
    };
  };
}
