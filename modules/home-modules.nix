{ lib, ... }:
{
  options.flake.homeModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.unspecified;
    default = { };
    description = "Cross-platform home modules, shared by NixOS and nix-darwin hosts.";
  };
}
