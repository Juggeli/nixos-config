{
  config,
  options,
  lib,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.user.impermanence;
  hasImpermanence = options.home ? persistence;
in
{
  options.plusultra.user.impermanence = with types; {
    enable = mkBoolOpt false "Whether or not to enable impermanence.";
    directories = mkOption {
      type = types.listOf types.anything;
      default = [ ];
      description = "Directories that should be persisted between reboots";
    };
    files = mkOption {
      type = types.listOf types.anything;
      default = [ ];
      description = "Files that should be persisted between reboots";
    };
  };

  config =
    if hasImpermanence then
      mkIf cfg.enable {
        home.persistence."/persist-home" = {
          removePrefixDirectory = false;
          allowOther = true;
          directories = [
            ".ssh"
            ".local/share/direnv"
            ".local/state/wireplumber"
            ".config/1Password"
            "src"
            "downloads"
            "documents"
            "games"
            "My Games"
            ".npm"
            ".var/app"
            ".config/SuperSlicer"
          ]
          ++ cfg.directories;
          files = cfg.files;
        };
      }
    else
      { };
}
