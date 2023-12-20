{ config, lib, ... }:
with lib;
with lib.plusultra; let
  cfg = config.plusultra.services.syncthing;
in
{
  options.plusultra.services.syncthing = with types; {
    enable = mkBoolOpt false "Whether or not to enable syncthing service.";
    dataDir = mkOpt str "/mnt/appdata/syncthing" "Syncthing data dir";
  };

  config = mkIf cfg.enable {
    services = {
      syncthing = {
        enable = true;
        user = "juggeli";
        dataDir = cfg.dataDir;
        configDir = "${cfg.dataDir}/.config/syncthing";
        guiAddress = "0.0.0.0:8384";
        overrideDevices = true;
        overrideFolders = true;
        settings = {
          devices = {
            "air" = { id = "TDYWB6T-LY5VAOF-X25VOXH-H6L3RUU-CN3ZFDM-NCM7YDY-NAI2P6H-723IBQZ"; };
            "haruka" = { id = "45RLMRL-COTJJV7-QXRIMZC-E2UR3P5-X5DV62Q-X6EO5HY-I4RJISU-BTPXIAB"; };
            "noel" = { id = "7WH7YG3-7UCT4KC-R27XT6G-RC6C7OF-JFQJJEH-JNVDCZJ-ZUZFFK4-3O25GQT"; };
            "iphone" = { id = "TO3YS4C-R4DPILJ-K7HNKRA-HUCB7MX-X7O5DR4-CP7OHOD-RRCX5BN-7PWIMQE"; };
          };
          folders = {
            "documents" = {
              path = "${cfg.dataDir}/documents";
              devices = [ "air" "haruka" "noel" ];
            };
            "downloads" = {
              path = "${cfg.dataDir}/downloads";
              devices = [ "air" "haruka" "noel" ];
            };
          };
        };
      };
    };

    # Syncthing ports
    networking.firewall.allowedTCPPorts = [ 8384 22000 ];
    networking.firewall.allowedUDPPorts = [ 22000 21027 ];
  };
}
