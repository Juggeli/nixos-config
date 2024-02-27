{ config, lib, inputs, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.user.impermanence;
in
{
  imports = [ (inputs.impermanence + "/home-manager.nix") ];

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

  config = mkIf cfg.enable {
    home.persistence."/persist-home" = {
      removePrefixDirectory = false;
      allowOther = true;
      directories = [
        ".ssh"
        ".local/share/direnv"
        ".mozilla"
        ".config/ArmCord"
        "src"
        "downloads"
        "documents"
        "Games"
        "Hydrus"
        "My Games"
        "obsidian"
      ] ++ cfg.directories;
      files = cfg.files;
    };
  };
}
