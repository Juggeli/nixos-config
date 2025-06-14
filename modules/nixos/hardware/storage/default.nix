{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.hardware.storage;
in
{
  imports = [
    ./smartd.nix
  ];

  options.plusultra.hardware.storage = with types; {
    enable = mkBoolOpt false "Whether or not to enable support for extra storage devices.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      ntfs3g
      fuseiso
      btrfs-progs
    ];
  };
}
