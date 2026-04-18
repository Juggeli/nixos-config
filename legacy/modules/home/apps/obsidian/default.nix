{
  config,
  lib,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.apps.obsidian;
in
{
  options.plusultra.apps.obsidian = with types; {
    enable = mkBoolOpt false "Whether or not to enable obsidian.";
  };

  config = mkIf cfg.enable {
    # Package installed with Flatpak
    plusultra.user.impermanence.directories = [
      ".config/obsidian"
      "obsidian"
      ".var/app/md.obsidian.Obsidian"
    ];
  };
}
