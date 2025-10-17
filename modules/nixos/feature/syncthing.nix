{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.plusultra;
let
  cfg = config.plusultra.feature.syncthing;
  syncthing-browser = pkgs.writeShellScriptBin "syncthing-browser" ''
    xdg-open http://${config.services.syncthing.guiAddress}
  '';
in
{
  options.plusultra.feature.syncthing = with types; {
    enable = mkBoolOpt false "Whether or not to enable syncthing service.";
    dataDir = mkOpt types.str "/home/${config.plusultra.user.name}" "Data dir location.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ syncthing-browser ];

    services = {
      syncthing = {
        enable = true;
        user = config.plusultra.user.name;
        configDir = "/var/lib/syncthing";
        dataDir = cfg.dataDir;
        key = config.age.secrets.syncthing-key.path;
        cert = config.age.secrets.syncthing-cert.path;
        guiAddress = "0.0.0.0:8384";
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
              path = "${config.services.syncthing.dataDir}/documents";
              devices = [
                "haruka"
                "noel"
                "kuro"
              ];
            };
            "downloads" = {
              path = "${config.services.syncthing.dataDir}/downloads";
              devices = [
                "haruka"
                "noel"
                "kuro"
              ];
            };
            "src" = {
              path = "${config.services.syncthing.dataDir}/src";
              devices = [
                "haruka"
                "noel"
                "kuro"
              ];
            };
            "orcaslicer" = {
              path = "${config.services.syncthing.dataDir}/.var/app/io.github.softfever.OrcaSlicer/config/OrcaSlicer";
              devices = [
                "haruka"
                "noel"
                "kuro"
              ];
            };
            "superslicer" = {
              path = "${config.services.syncthing.dataDir}/.config/SuperSlicer";
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

    # Ensure Syncthing waits for impermanence mounts
    systemd.services.syncthing = mkIf cfg.enable {
      after = [ "local-fs.target" ];
      wants = [ "local-fs.target" ];
    };

    plusultra.filesystem.impermanence.directories = [ "/var/lib/syncthing" ];

    # Syncthing ports
    networking.firewall.allowedTCPPorts = [
      8384
      22000
    ];
    networking.firewall.allowedUDPPorts = [
      22000
      21027
    ];
  };
}
