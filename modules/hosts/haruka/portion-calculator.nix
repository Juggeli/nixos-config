{
  flake.nixosModules.haruka-portion-calculator =
    { pkgs, ... }:
    let
      dataDir = "/mnt/appdata/portion-calculator";
      port = 8091;
    in
    {
      users.users.portion-calculator = {
        isSystemUser = true;
        group = "portion-calculator";
      };
      users.groups.portion-calculator = { };

      systemd.services.portion-calculator = {
        description = "Portion Calculator";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          User = "portion-calculator";
          Group = "portion-calculator";
          ExecStart = "${pkgs.portion-calculator}/bin/portion-calculator";
          Environment = [
            "DATA_FILE=${dataDir}/data.json"
            "PORT=${toString port}"
            "HOST=127.0.0.1"
          ];
          ReadWritePaths = [ dataDir ];
          ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${dataDir}";
          Restart = "on-failure";
        };
      };

      # The data dir lives on a persistent ZFS dataset owned by root; hand it
      # to the service user once, after the dataset is mounted.
      systemd.tmpfiles.rules = [
        "d ${dataDir} 0750 portion-calculator portion-calculator -"
      ];
    };
}
