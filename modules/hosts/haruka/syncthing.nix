{
  flake.nixosModules.haruka-syncthing =
    { config, ... }:
    let
      dataDir = "/mnt/appdata/syncthing";
      shared = [
        "haruka"
        "noel"
        "kuro"
      ];
    in
    {
      services.syncthing = {
        enable = true;
        user = "juggeli";
        configDir = "/var/lib/syncthing";
        inherit dataDir;
        key = config.age.secrets.syncthing-key.path;
        cert = config.age.secrets.syncthing-cert.path;
        guiAddress = "127.0.0.1:8384";
        overrideDevices = true;
        overrideFolders = true;
        settings = {
          # The GUI listens on loopback and is reached through Tailscale Serve,
          # whose forwarded Host header syncthing's rebinding check rejects.
          gui.insecureSkipHostcheck = true;

          devices = {
            "haruka".id = "45RLMRL-COTJJV7-QXRIMZC-E2UR3P5-X5DV62Q-X6EO5HY-I4RJISU-BTPXIAB";
            "noel".id = "7WH7YG3-7UCT4KC-R27XT6G-RC6C7OF-JFQJJEH-JNVDCZJ-ZUZFFK4-3O25GQT";
            "kuro".id = "UOFUCBZ-U7MBVHS-76CW6Z3-M2U4ANF-B7O3JAV-L7N75Z3-BIEDFDK-XSDWKA7";
          };
          folders = {
            "documents" = {
              path = "${dataDir}/documents";
              devices = shared;
              versioning = {
                type = "staggered";
                params = {
                  cleanInterval = "3600";
                  maxAge = "2592000";
                };
              };
            };
            "downloads" = {
              path = "${dataDir}/downloads";
              devices = shared;
              versioning = {
                type = "staggered";
                params = {
                  cleanInterval = "3600";
                  maxAge = "2592000";
                };
              };
            };
            "src" = {
              path = "${dataDir}/src";
              devices = shared;
              ignorePatterns = [ "dotfiles" ];
              versioning = {
                type = "staggered";
                params = {
                  cleanInterval = "3600";
                  maxAge = "2592000";
                };
              };
            };
            "orcaslicer" = {
              path = "${dataDir}/.var/app/io.github.softfever.OrcaSlicer/config/OrcaSlicer";
              devices = shared;
              versioning = {
                type = "staggered";
                params = {
                  cleanInterval = "3600";
                  maxAge = "2592000";
                };
              };
            };
            "superslicer" = {
              path = "${dataDir}/.config/SuperSlicer";
              devices = shared;
              versioning = {
                type = "staggered";
                params = {
                  cleanInterval = "3600";
                  maxAge = "2592000";
                };
              };
            };
          };
        };
      };

      systemd.services.syncthing = {
        after = [ "local-fs.target" ];
        wants = [ "local-fs.target" ];
      };

      # 8384 is the unauthenticated web GUI, reached over Tailscale Serve.
      # 22000/21027 carry the actual sync protocol and must stay open.
      networking.firewall.allowedTCPPorts = [
        22000
      ];
      networking.firewall.allowedUDPPorts = [
        22000
        21027
      ];
    };
}
