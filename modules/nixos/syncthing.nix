{
  flake.nixosModules.syncthing =
    { config, pkgs, ... }:
    let
      syncthing-browser = pkgs.writeShellScriptBin "syncthing-browser" ''
        xdg-open http://${config.services.syncthing.guiAddress}
      '';
    in
    {
      environment.systemPackages = [ syncthing-browser ];

      services.syncthing = {
        enable = true;
        user = "juggeli";
        configDir = "/var/lib/syncthing";
        dataDir = "/home/juggeli";
        key = config.age.secrets.syncthing-key.path;
        cert = config.age.secrets.syncthing-cert.path;
        guiAddress = "0.0.0.0:8384";
        overrideDevices = true;
        overrideFolders = true;
        settings = {
          devices = {
            "haruka".id = "45RLMRL-COTJJV7-QXRIMZC-E2UR3P5-X5DV62Q-X6EO5HY-I4RJISU-BTPXIAB";
            "noel".id = "7WH7YG3-7UCT4KC-R27XT6G-RC6C7OF-JFQJJEH-JNVDCZJ-ZUZFFK4-3O25GQT";
            "kuro".id = "UOFUCBZ-U7MBVHS-76CW6Z3-M2U4ANF-B7O3JAV-L7N75Z3-BIEDFDK-XSDWKA7";
          };
          folders =
            let
              shared = [
                "haruka"
                "noel"
                "kuro"
              ];
            in
            {
              "documents" = {
                path = "${config.services.syncthing.dataDir}/documents";
                devices = shared;
              };
              "downloads" = {
                path = "${config.services.syncthing.dataDir}/downloads";
                devices = shared;
              };
              "src" = {
                path = "${config.services.syncthing.dataDir}/src";
                devices = shared;
                ignorePatterns = [ "dotfiles" ];
              };
              "orcaslicer" = {
                path = "${config.services.syncthing.dataDir}/.var/app/io.github.softfever.OrcaSlicer/config/OrcaSlicer";
                devices = shared;
              };
              "superslicer" = {
                path = "${config.services.syncthing.dataDir}/.config/SuperSlicer";
                devices = shared;
              };
            };
        };
      };

      systemd.services.syncthing = {
        after = [ "local-fs.target" ];
        wants = [ "local-fs.target" ];
      };

      environment.persistence."/persist".directories = [ "/var/lib/syncthing" ];

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
