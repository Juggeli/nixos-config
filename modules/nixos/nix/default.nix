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
        auto-optimise-store = true;
        trusted-users = users;
        allowed-users = users;
        download-buffer-size = 134217728;
      };

      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
      package = pkgs.nixVersions.latest;

      # flake-utils-plus
      generateRegistryFromInputs = true;
      generateNixPathFromInputs = true;
      linkInputs = true;
    };

    systemd.services.nix-gc = {
      preStart = ''
        ${pkgs.nix}/bin/nix-env --delete-generations 30d --profile /home/${config.plusultra.user.name}/.local/state/nix/profiles/home-manager || true
      '';
    };
  };
}
