{
  flake.homeModules.syncthing =
    { lib, pkgs, ... }:
    let
      homeDir = if pkgs.stdenv.isDarwin then "/Users/juggeli" else "/home/juggeli";
    in
    {
      home-manager.users.juggeli.services.syncthing = {
        enable = true;
        tray = lib.mkIf pkgs.stdenv.isLinux {
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
              ignorePatterns = [ "dotfiles" ];
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
    };
}
