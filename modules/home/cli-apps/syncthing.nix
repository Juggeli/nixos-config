{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.cli-apps.syncthing;
  homeDir = config.home.homeDirectory;
in
{
  options.plusultra.cli-apps.syncthing = with types; {
    enable = mkBoolOpt false "Whether or not to enable syncthing service.";
  };

  config = mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      tray = mkIf pkgs.stdenv.isLinux {
        enable = true;
      };
      overrideDevices = true;
      overrideFolders = true;
      settings = {
        devices = {
          "haruka" = {
            id = "45RLMRL-COTJJV7-QXRIMZC-E2UR3P5-X5DV62Q-X6EO5HY-I4RJISU-BTPXIAB";
          };
          "noel" = {
            id = "7WH7YG3-7UCT4KC-R27XT6G-RC6C7OF-JFQJJEH-JNVDCZJ-ZUZFFK4-3O25GQT";
          };
          "kuro" = {
            id = "UOFUCBZ-U7MBVHS-76CW6Z3-M2U4ANF-B7O3JAV-L7N75Z3-BIEDFDK-XSDWKA7";
          };
        };
        folders = {
          "documents" = {
            path = "${homeDir}/Documents";
            devices = [
              "haruka"
              "noel"
              "kuro"
            ];
          };
          "downloads" = {
            path = "${homeDir}/Downloads";
            devices = [
              "haruka"
              "noel"
              "kuro"
            ];
          };
          "src" = {
            path = "${homeDir}/src";
            devices = [
              "haruka"
              "noel"
              "kuro"
            ];
          };
          "orcaslicer" = {
            path =
              if pkgs.stdenv.isDarwin then
                "${homeDir}/Library/Application Support/OrcaSlicer"
              else
                "${homeDir}/.var/app/io.github.softfever.OrcaSlicer/config/OrcaSlicer";
            devices = [
              "haruka"
              "noel"
              "kuro"
            ];
          };
          "superslicer" = {
            path =
              if pkgs.stdenv.isDarwin then
                "${homeDir}/Library/Application Support/SuperSlicer"
              else
                "${homeDir}/.config/SuperSlicer";
            devices = [
              "haruka"
              "noel"
              "kuro"
            ];
          };
        };
      };
    };

    plusultra.user.impermanence = {
      directories = [
        ".config/syncthing"
        ".local/state/syncthing"
      ];
    };
  };
}
